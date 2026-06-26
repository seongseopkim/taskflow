from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role


class ListCreate(BaseModel):
    title : str

class ListUpdate(BaseModel):
    title : Optional[str] = None

class ListResponse(BaseModel):
    id : int
    board_id : int
    title : str
    position : float
    created_at : datetime

    class Config:
        from_attributes = True