import firebase_admin
from firebase_admin import auth, credentials, firestore
from google.cloud.firestore import AsyncClient
from functools import lru_cache
from typing import Optional
import os

from .config import get_settings


_firebase_app: Optional[firebase_admin.App] = None
_firestore_client: Optional[AsyncClient] = None


def init_firebase() -> firebase_admin.App:
    """Initialize Firebase Admin SDK."""
    global _firebase_app
    
    if _firebase_app is not None:
        return _firebase_app
    
    settings = get_settings()
    
    # Initialize with credentials
    if settings.google_application_credentials:
        cred = credentials.Certificate(settings.google_application_credentials)
        _firebase_app = firebase_admin.initialize_app(cred, {
            'projectId': settings.firebase_project_id,
        })
    else:
        # Use default credentials (for Cloud Run)
        _firebase_app = firebase_admin.initialize_app()
    
    return _firebase_app


def get_firebase_app() -> firebase_admin.App:
    """Get Firebase app instance."""
    global _firebase_app
    if _firebase_app is None:
        return init_firebase()
    return _firebase_app


async def verify_firebase_token(token: str) -> dict:
    """
    Verify Firebase ID token and return decoded claims.
    
    Raises:
        ValueError: If token is invalid
    """
    try:
        # Ensure Firebase is initialized
        get_firebase_app()
        
        # Verify the token
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise ValueError(f"Invalid token: {str(e)}")


def get_firestore_client():
    """Get Firestore client for the 'amorae' database."""
    global _firestore_client
    
    if _firestore_client is None:
        get_firebase_app()
        # Use the named "amorae" database instead of "(default)"
        _firestore_client = firestore.client(database_id='amorae')
    
    return _firestore_client
