from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role

class LabelCreate(BaseModel):
    name : str
    color : str

class LabelResponse(BaseModel):
    id : int
    board_id : int
    name : str
    color : str

