from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role

class CommentCreate(BaseModel):
    content : str

class CommentResponse(BaseModel):
    id : int
    card_id : int
    user_id : int
    content: str
    created_at : datetime

    class Config:
        from_attributes = True

