from typing import AsyncGenerator, Optional
from google.cloud import firestore
import uuid
import time

from ..core.firebase import get_firestore_client
from ..core.auth import AuthenticatedUser
from ..models.schemas import (
    SendMessageRequest,
    SendMessageResponse,
    SSEMetaEvent,
    SSEDeltaEvent,
    SSEFinalEvent,
    SSEErrorEvent,
    UserPreferences,
    Fact,
    ThreadSummary,
)
from .llm_service import get_llm_service


class ChatService:
    """Service for handling chat operations."""
    
    def __init__(self):
        self.db = get_firestore_client()
        self.llm = get_llm_service()
    
    async def send_message(
        self,
        user: AuthenticatedUser,
        request: SendMessageRequest,
        request_id: str,
    ) -> SendMessageResponse:
        """
        Process user message and return complete AI response (non-streaming).
        Simple approach: save messages, generate response, return it.
        """
        thread_id = request.thread_id
        generation_id = str(uuid.uuid4())
        
        # Verify thread ownership
        thread_ref = self.db.collection("threads").document(thread_id)
        thread_doc = thread_ref.get()
        
        if not thread_doc.exists:
            raise ValueError("Thread not found")
        
        thread_data = thread_doc.to_dict()
        if thread_data.get("userId") != user.uid:
            raise PermissionError("Not authorized to access this thread")
        
        # Get user preferences
        user_ref = self.db.collection("users").document(user.uid)
        user_doc = user_ref.get()
        user_data = user_doc.to_dict() if user_doc.exists else {}
        
        preferences = UserPreferences(**(user_data.get("prefs", {})))
        user_name = user_data.get("displayName", "Friend")
        
        # Get user facts
        facts_ref = self.db.collection("users").document(user.uid).collection("facts")
        facts_docs = facts_ref.where("status", "==", "active").stream()
        facts = [Fact(id=doc.id, **doc.to_dict()) for doc in facts_docs]
        
        # Get thread summary if exists
        summary = None
        summary_state = thread_data.get("summary", {})
        if summary_state.get("text"):
            summary = ThreadSummary(
                text=summary_state["text"],
                from_seq=summary_state.get("fromSeq", 0),
                to_seq=summary_state.get("toSeq", 0),
            )
        
        # Get recent messages (last 20)
        messages_ref = (
            thread_ref.collection("messages")
            .order_by("seq", direction=firestore.Query.DESCENDING)
            .limit(20)
        )
        messages_docs = list(messages_ref.stream())
        messages_docs.reverse()  # Oldest first
        
        # Convert to LLM format
        messages = []
        for doc in messages_docs:
            msg_data = doc.to_dict()
            messages.append({
                "role": msg_data.get("role", "user"),
                "content": msg_data.get("content", ""),
                "attachments": msg_data.get("attachments", []),
            })
        
        # Add current user message
        user_message = {
            "role": "user",
            "content": request.content,
            "attachments": [a.model_dump() for a in (request.attachments or [])],
        }
        messages.append(user_message)
        
        # Get next sequence number
        next_seq = thread_data.get("messageCount", 0) + 1
        
        # Save user message to Firestore
        user_msg_id = str(uuid.uuid4())
        user_msg_ref = thread_ref.collection("messages").document(user_msg_id)
        user_msg_ref.set({
            "id": user_msg_id,
            "role": "user",
            "content": request.content,
            "attachments": [a.model_dump() for a in (request.attachments or [])],
            "seq": next_seq,
            "createdAt": firestore.SERVER_TIMESTAMP,
        })
        
        # Generate complete AI response
        full_response = await self.llm.generate(
            messages=messages,
            user_name=user_name,
            user_gender=user_data.get("gender"),
            preferences=preferences,
            facts=facts,
            summary=summary,
        )
        
        # Create assistant message
        assistant_msg_id = str(uuid.uuid4())
        assistant_msg_ref = thread_ref.collection("messages").document(assistant_msg_id)
        assistant_msg_ref.set({
            "id": assistant_msg_id,
            "role": "assistant",
            "content": full_response,
            "seq": next_seq + 1,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "aiMeta": {
                "generationId": generation_id,
                "tokensUsed": len(full_response) // 4,  # Rough estimate
                "finishReason": "stop",
            },
        })
        
        # Update thread
        thread_ref.update({
            "messageCount": next_seq + 1,
            "lastMessageAt": firestore.SERVER_TIMESTAMP,
            "state.lastActivityAt": int(time.time() * 1000),
        })
        
        return SendMessageResponse(
            assistantMessageId=assistant_msg_id,
            content=full_response,
            generationId=generation_id,
        )
    
    async def send_message_stream(
        self,
        user: AuthenticatedUser,
        request: SendMessageRequest,
        request_id: str,
    ) -> AsyncGenerator[str, None]:
        """
        Process user message and stream AI response.
        
        Yields SSE-formatted events.
        """
        thread_id = request.thread_id
        generation_id = str(uuid.uuid4())
        
        try:
            # Verify thread ownership
            thread_ref = self.db.collection("threads").document(thread_id)
            thread_doc = thread_ref.get()
            
            if not thread_doc.exists:
                yield self._format_sse("error", SSEErrorEvent(
                    code="THREAD_NOT_FOUND",
                    message="Thread not found",
                ).model_dump())
                return
            
            thread_data = thread_doc.to_dict()
            if thread_data.get("userId") != user.uid:
                yield self._format_sse("error", SSEErrorEvent(
                    code="UNAUTHORIZED",
                    message="Not authorized to access this thread",
                ).model_dump())
                return
            
            # Get user preferences
            user_ref = self.db.collection("users").document(user.uid)
            user_doc = user_ref.get()
            user_data = user_doc.to_dict() if user_doc.exists else {}
            
            preferences = UserPreferences(**(user_data.get("prefs", {})))
            user_name = user_data.get("displayName", "Friend")
            
            # Get user facts
            facts_ref = self.db.collection("users").document(user.uid).collection("facts")
            facts_docs = facts_ref.where("status", "==", "active").stream()
            facts = [Fact(id=doc.id, **doc.to_dict()) for doc in facts_docs]
            
            # Get thread summary if exists
            summary = None
            summary_state = thread_data.get("summary", {})
            if summary_state.get("text"):
                summary = ThreadSummary(
                    text=summary_state["text"],
                    from_seq=summary_state.get("fromSeq", 0),
                    to_seq=summary_state.get("toSeq", 0),
                )
            
            # Get recent messages (last 20)
            messages_ref = (
                thread_ref.collection("messages")
                .order_by("seq", direction=firestore.Query.DESCENDING)
                .limit(20)
            )
            messages_docs = list(messages_ref.stream())
            messages_docs.reverse()  # Oldest first
            
            # Convert to LLM format
            messages = []
            for doc in messages_docs:
                msg_data = doc.to_dict()
                messages.append({
                    "role": msg_data.get("role", "user"),
                    "content": msg_data.get("content", ""),
                    "attachments": msg_data.get("attachments", []),
                })
            
            # Add current user message
            user_message = {
                "role": "user",
                "content": request.content,
                "attachments": [a.model_dump() for a in (request.attachments or [])],
            }
            messages.append(user_message)
            
            # Get next sequence number
            next_seq = thread_data.get("messageCount", 0) + 1
            
            # Save user message to Firestore
            user_msg_id = str(uuid.uuid4())
            user_msg_ref = thread_ref.collection("messages").document(user_msg_id)
            user_msg_ref.set({
                "id": user_msg_id,
                "role": "user",
                "content": request.content,
                "attachments": [a.model_dump() for a in (request.attachments or [])],
                "seq": next_seq,
                "createdAt": firestore.SERVER_TIMESTAMP,
            })
            
            # Create assistant message placeholder
            assistant_msg_id = str(uuid.uuid4())
            assistant_msg_ref = thread_ref.collection("messages").document(assistant_msg_id)
            assistant_msg_ref.set({
                "id": assistant_msg_id,
                "role": "assistant",
                "content": "",
                "seq": next_seq + 1,
                "createdAt": firestore.SERVER_TIMESTAMP,
                "streamState": {
                    "status": "streaming",
                    "generationId": generation_id,
                },
            })
            
            # Update thread
            thread_ref.update({
                "messageCount": next_seq + 1,
                "lastMessageAt": firestore.SERVER_TIMESTAMP,
                "state.lastActivityAt": int(time.time() * 1000),
            })
            
            # Emit meta event
            yield self._format_sse("meta", SSEMetaEvent(
                threadId=thread_id,
                assistantMessageId=assistant_msg_id,
                generationId=generation_id,
                requestId=request_id,
            ).model_dump(by_alias=True))
            
            # Emit thinking stage
            yield self._format_sse("stage", {"name": "thinking", "status": "started"})
            
            # Stream LLM response
            full_response = ""
            cursor = 0
            
            async for chunk in self.llm.generate_stream(
                messages=messages,
                user_name=user_name,
                preferences=preferences,
                facts=facts,
                summary=summary,
            ):
                full_response += chunk
                cursor += len(chunk)
                
                yield self._format_sse("delta", SSEDeltaEvent(
                    cursor=cursor,
                    text=chunk,
                ).model_dump())
            
            # Update assistant message with final content
            assistant_msg_ref.update({
                "content": full_response,
                "streamState": {
                    "status": "completed",
                    "generationId": generation_id,
                    "cursor": cursor,
                    "completedAt": int(time.time() * 1000),
                },
                "aiMeta": {
                    "generationId": generation_id,
                    "tokensUsed": cursor // 4,  # Rough estimate
                    "latencyMs": 0,  # TODO: Track actual latency
                    "finishReason": "stop",
                },
            })
            
            # Emit final event
            yield self._format_sse("final", SSEFinalEvent(
                cursor=cursor,
                finishReason="stop",
            ).model_dump(by_alias=True))
            
        except Exception as e:
            yield self._format_sse("error", SSEErrorEvent(
                code="INTERNAL_ERROR",
                message=str(e),
            ).model_dump())
    
    def _format_sse(self, event: str, data: dict) -> str:
        """Format data as SSE event."""
        import json
        return f"event: {event}\ndata: {json.dumps(data)}\n\n"


# Singleton
_chat_service: Optional[ChatService] = None


def get_chat_service() -> ChatService:
    """Get chat service singleton."""
    global _chat_service
    if _chat_service is None:
        _chat_service = ChatService()
    return _chat_service
