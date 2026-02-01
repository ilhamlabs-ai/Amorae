from fastapi import APIRouter, Depends, HTTPException
from google.cloud import firestore as fs

from ..core.auth import AuthenticatedUser, get_current_user
from ..core.firebase import get_firestore_client


router = APIRouter(prefix="/v1/privacy", tags=["privacy"])


@router.post("/delete_user")
async def delete_user_data(
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Delete all user data (GDPR compliance).
    
    This will:
    1. Delete all user messages
    2. Delete all user threads
    3. Delete all user facts
    4. Delete user document
    
    Note: This does NOT delete the Firebase Auth account.
    """
    db = get_firestore_client()
    
    try:
        # Delete all threads and their messages
        threads_ref = db.collection("threads").where("userId", "==", user.uid)
        threads = list(threads_ref.stream())
        
        for thread_doc in threads:
            # Delete messages in thread
            messages_ref = thread_doc.reference.collection("messages")
            messages = list(messages_ref.stream())
            for msg_doc in messages:
                msg_doc.reference.delete()
            
            # Delete thread
            thread_doc.reference.delete()
        
        # Delete all facts
        facts_ref = db.collection("users").document(user.uid).collection("facts")
        facts = list(facts_ref.stream())
        for fact_doc in facts:
            fact_doc.reference.delete()
        
        # Delete user document
        db.collection("users").document(user.uid).delete()
        
        return {
            "success": True,
            "deleted": {
                "threads": len(threads),
                "facts": len(facts),
            },
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete data: {str(e)}")


@router.get("/export_data")
async def export_user_data(
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Export all user data (GDPR compliance).
    
    Returns all user data in a structured format.
    """
    db = get_firestore_client()
    
    try:
        # Get user document
        user_doc = db.collection("users").document(user.uid).get()
        user_data = user_doc.to_dict() if user_doc.exists else {}
        
        # Get all threads and messages
        threads_data = []
        threads_ref = db.collection("threads").where("userId", "==", user.uid)
        threads = list(threads_ref.stream())
        
        for thread_doc in threads:
            thread = thread_doc.to_dict()
            
            # Get messages
            messages_ref = (
                thread_doc.reference.collection("messages")
                .order_by("seq")
            )
            messages = [msg.to_dict() for msg in messages_ref.stream()]
            
            threads_data.append({
                **thread,
                "messages": messages,
            })
        
        # Get all facts
        facts_ref = db.collection("users").document(user.uid).collection("facts")
        facts = [fact.to_dict() for fact in facts_ref.stream()]
        
        return {
            "user": user_data,
            "threads": threads_data,
            "facts": facts,
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export data: {str(e)}")
