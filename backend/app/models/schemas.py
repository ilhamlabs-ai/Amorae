from pydantic import BaseModel, Field
from typing import Optional, List, Literal
from datetime import datetime


class MessageAttachment(BaseModel):
    """Attachment in a message (image)."""
    kind: Literal["image"] = "image"
    storage_path: str = Field(..., alias="storagePath")
    download_url: str = Field(..., alias="downloadUrl")
    mime_type: str = Field(..., alias="mimeType")
    width: Optional[int] = None
    height: Optional[int] = None
    size_bytes: Optional[int] = Field(None, alias="sizeBytes")
    
    class Config:
        populate_by_name = True


class SendMessageRequest(BaseModel):
    """Request body for sending a message."""
    thread_id: str = Field(..., alias="threadId")
    content: str
    attachments: Optional[List[MessageAttachment]] = None
    
    class Config:
        populate_by_name = True


class SendMessageResponse(BaseModel):
    """Response for non-streaming message send."""
    assistant_message_id: str = Field(..., alias="assistantMessageId")
    content: str
    generation_id: str = Field(..., alias="generationId")
    
    class Config:
        populate_by_name = True


class CurateMemoryRequest(BaseModel):
    """Request body for memory curation."""
    thread_id: str = Field(..., alias="threadId")
    from_seq: int = Field(..., alias="fromSeq")
    to_seq: int = Field(..., alias="toSeq")
    
    class Config:
        populate_by_name = True


class SSEMetaEvent(BaseModel):
    """SSE meta event data."""
    thread_id: str = Field(..., alias="threadId")
    assistant_message_id: str = Field(..., alias="assistantMessageId")
    generation_id: str = Field(..., alias="generationId")
    request_id: str = Field(..., alias="requestId")
    
    class Config:
        populate_by_name = True


class SSEDeltaEvent(BaseModel):
    """SSE delta event data."""
    cursor: int
    text: str


class SSEFinalEvent(BaseModel):
    """SSE final event data."""
    cursor: int
    finish_reason: str = Field(..., alias="finishReason")
    
    class Config:
        populate_by_name = True


class SSEErrorEvent(BaseModel):
    """SSE error event data."""
    code: str
    message: str


class UserPreferences(BaseModel):
    """User AI preferences."""
    selected_persona: str = Field("amora", alias="selectedPersona")
    custom_persona_name: Optional[str] = Field(None, alias="customPersonaName")
    relationship_mode: str = Field("friendly", alias="relationshipMode")
    companion_style: str = Field("warm_supportive", alias="companionStyle")
    comfort_approach: str = Field("balanced", alias="comfortApproach")
    emoji_level: str = Field("medium", alias="emojiLevel")
    pet_names_allowed: bool = Field(False, alias="petNamesAllowed")
    flirting_allowed: bool = Field(False, alias="flirtingAllowed")
    topics_to_avoid: List[str] = Field(default_factory=list, alias="topicsToAvoid")
    phrases_to_avoid: List[str] = Field(default_factory=list, alias="phrasesToAvoid")
    
    class Config:
        populate_by_name = True


class ThreadSummary(BaseModel):
    """Summary of a conversation thread."""
    text: str
    from_seq: int = Field(..., alias="fromSeq")
    to_seq: int = Field(..., alias="toSeq")
    
    class Config:
        populate_by_name = True


class Fact(BaseModel):
    """A durable fact about the user."""
    id: str
    type: Literal["profile", "preference", "project", "constraint", "emotional"]
    key: str
    value: str
    confidence: float = 0.8
    importance: float = 0.5
    status: Literal["active", "deprecated"] = "active"
    
    class Config:
        populate_by_name = True
