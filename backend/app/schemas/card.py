from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role


class CardCreate(BaseModel):
    title : str
    description : Optional[str] = None
    assignee_id : Optional[int] = None
    due_date : Optional[datetime] = None

class CardUpdate(BaseModel):
    title : Optional[str] = None
    description : Optional[str] = None
    assignee_id : Optional[int] = None
    due_date : Optional[datetime] = None

class CardMove(BaseModel) :
    target_list_id : int
    position : float

class CardResponse(BaseModel):
    id : int
    list_id : int
    title : str
    description : Optional[str] = None
    assignee_id : Optional[int] = None
    due_date : Optional[datetime] = None
    position : float
    created_at : datetime

    class Config:
        from_attributes = True

