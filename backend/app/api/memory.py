from fastapi import APIRouter, Depends, HTTPException

from ..core.auth import AuthenticatedUser, get_current_user
from ..models.schemas import CurateMemoryRequest
from ..services.memory_service import get_memory_service


router = APIRouter(prefix="/v1/memory", tags=["memory"])


@router.post("/curate")
async def curate_memory(
    body: CurateMemoryRequest,
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Trigger memory curation for a message range.
    
    Extracts facts from the conversation and stores them for long-term memory.
    """
    memory_service = get_memory_service()
    
    try:
        result = await memory_service.curate_memory(user, body)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/facts")
async def get_facts(
    user: AuthenticatedUser = Depends(get_current_user),
):
    """Get all active facts for the current user."""
    memory_service = get_memory_service()
    facts = await memory_service.get_user_facts(user)
    return {"facts": facts}


@router.delete("/facts/{fact_id}")
async def delete_fact(
    fact_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
):
    """Delete (deprecate) a fact."""
    memory_service = get_memory_service()
    success = await memory_service.delete_fact(user, fact_id)
    if not success:
        raise HTTPException(status_code=404, detail="Fact not found")
    return {"success": True}
