from fastapi import APIRouter, Depends, Request
from sse_starlette.sse import EventSourceResponse

from ..core.auth import AuthenticatedUser, get_current_user, get_request_id
from ..models.schemas import SendMessageRequest, SendMessageResponse
from ..services.chat_service import get_chat_service


router = APIRouter(prefix="/v1/chat", tags=["chat"])


@router.post("/send", response_model=SendMessageResponse)
async def send_message(
    body: SendMessageRequest,
    user: AuthenticatedUser = Depends(get_current_user),
    request_id: str = Depends(get_request_id),
):
    """
    Send a message and receive complete AI response (non-streaming).
    Simple endpoint that returns the full response at once.
    """
    chat_service = get_chat_service()
    return await chat_service.send_message(user, body, request_id)


@router.post("/send_stream")
async def send_message_stream(
    request: Request,
    body: SendMessageRequest,
    user: AuthenticatedUser = Depends(get_current_user),
    request_id: str = Depends(get_request_id),
):
    """
    Send a message and receive streaming AI response via SSE.
    
    Events:
    - meta: Thread and message IDs
    - stage: Processing stages (thinking, etc.)
    - delta: Text chunks
    - heartbeat: Keep-alive
    - final: Completion with finish reason
    - error: Error details
    """
    chat_service = get_chat_service()
    
    async def event_generator():
        async for event in chat_service.send_message_stream(user, body, request_id):
            yield event
    
    return EventSourceResponse(
        event_generator(),
        media_type="text/event-stream",
    )
