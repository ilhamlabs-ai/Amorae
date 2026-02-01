from fastapi import Request, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional

from .firebase import verify_firebase_token


security = HTTPBearer()


class AuthenticatedUser:
    """Authenticated user from Firebase token."""
    
    def __init__(self, uid: str, email: Optional[str] = None, name: Optional[str] = None):
        self.uid = uid
        self.email = email
        self.name = name
    
    @classmethod
    def from_token(cls, decoded_token: dict) -> "AuthenticatedUser":
        return cls(
            uid=decoded_token["uid"],
            email=decoded_token.get("email"),
            name=decoded_token.get("name"),
        )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> AuthenticatedUser:
    """
    Dependency to get current authenticated user from Firebase token.
    
    Raises:
        HTTPException: If token is invalid or missing
    """
    try:
        token = credentials.credentials
        decoded_token = await verify_firebase_token(token)
        return AuthenticatedUser.from_token(decoded_token)
    except ValueError as e:
        raise HTTPException(
            status_code=401,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_request_id(request: Request) -> str:
    """Get request ID from header for idempotency."""
    request_id = request.headers.get("X-Request-Id")
    if not request_id:
        raise HTTPException(
            status_code=400,
            detail="X-Request-Id header is required",
        )
    return request_id
