from typing import Optional
from google.cloud import firestore
import uuid
import time

from ..core.firebase import get_firestore_client
from ..core.auth import AuthenticatedUser
from ..models.schemas import CurateMemoryRequest, Fact
from .llm_service import get_llm_service


class MemoryService:
    """Service for managing user memory (facts)."""
    
    def __init__(self):
        self.db = get_firestore_client()
        self.llm = get_llm_service()
    
    async def curate_memory(
        self,
        user: AuthenticatedUser,
        request: CurateMemoryRequest,
    ) -> dict:
        """
        Curate memory from a conversation range.
        
        Extracts facts and stores them in the user's facts collection.
        """
        thread_id = request.thread_id
        
        # Verify thread ownership
        thread_ref = self.db.collection("threads").document(thread_id)
        thread_doc = thread_ref.get()
        
        if not thread_doc.exists:
            raise ValueError("Thread not found")
        
        thread_data = thread_doc.to_dict()
        if thread_data.get("userId") != user.uid:
            raise ValueError("Not authorized")
        
        # Get messages in range
        messages_ref = (
            thread_ref.collection("messages")
            .where("seq", ">=", request.from_seq)
            .where("seq", "<=", request.to_seq)
            .order_by("seq")
        )
        messages_docs = list(messages_ref.stream())
        
        messages = []
        for doc in messages_docs:
            msg_data = doc.to_dict()
            messages.append({
                "role": msg_data.get("role", "user"),
                "content": msg_data.get("content", ""),
            })
        
        if not messages:
            return {"facts_created": 0}
        
        # Get existing facts
        facts_ref = self.db.collection("users").document(user.uid).collection("facts")
        facts_docs = list(facts_ref.stream())
        existing_facts = [Fact(id=doc.id, **doc.to_dict()) for doc in facts_docs]
        
        # Extract new facts
        new_facts = await self.llm.extract_facts(messages, existing_facts)
        
        # Store new facts
        facts_created = 0
        for fact_data in new_facts:
            fact_id = str(uuid.uuid4())
            facts_ref.document(fact_id).set({
                **fact_data,
                "id": fact_id,
                "scope": "global",
                "status": "active",
                "source": {
                    "kind": "conversation",
                    "threadId": thread_id,
                    "messageSeqStart": request.from_seq,
                    "messageSeqEnd": request.to_seq,
                    "createdAt": int(time.time() * 1000),
                },
                "createdAt": firestore.SERVER_TIMESTAMP,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            })
            facts_created += 1
        
        return {"facts_created": facts_created}
    
    async def get_user_facts(self, user: AuthenticatedUser) -> list:
        """Get all active facts for a user."""
        facts_ref = (
            self.db.collection("users")
            .document(user.uid)
            .collection("facts")
            .where("status", "==", "active")
            .order_by("importance", direction=firestore.Query.DESCENDING)
        )
        
        facts_docs = list(facts_ref.stream())
        return [{"id": doc.id, **doc.to_dict()} for doc in facts_docs]
    
    async def delete_fact(self, user: AuthenticatedUser, fact_id: str) -> bool:
        """Delete (deprecate) a fact."""
        fact_ref = (
            self.db.collection("users")
            .document(user.uid)
            .collection("facts")
            .document(fact_id)
        )
        
        fact_doc = fact_ref.get()
        if not fact_doc.exists:
            return False
        
        fact_ref.update({
            "status": "deprecated",
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })
        
        return True


# Singleton
_memory_service: Optional[MemoryService] = None


def get_memory_service() -> MemoryService:
    """Get memory service singleton."""
    global _memory_service
    if _memory_service is None:
        _memory_service = MemoryService()
    return _memory_service
