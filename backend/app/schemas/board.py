from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role
from typing import List as ListType   # 이름 충돌 피하려고 별명 붙임

from app.schemas.card import CardResponse

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

class ListWithCards(BaseModel):
    id: int
    board_id: int
    title: str
    position: float
    cards: ListType[CardResponse]   # ← 카드들까지 포함

    class Config:
        from_attributes = True
        
class BoardDetailResponse(BaseModel):
    id: int
    workspace_id: int
    name: str
    created_at: datetime
    lists: ListType[ListWithCards]   # ← 리스트들, 각 리스트 안에 카드까지

    class Config:
        from_attributes = True

