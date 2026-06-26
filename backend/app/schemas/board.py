from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role


class BoardCreate(BaseModel):

    name : str

class BoardUpdate(BaseModel):
    name : Optional[str] = None

class BoardResponse(BaseModel):

    id : int
    workspace_id : int
    name : str
    created_at : datetime

    class Config:
        from_attributes = True

