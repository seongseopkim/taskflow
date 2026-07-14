"""필요한 것:
- NotificationResponse → 조회 응답 (id, type, content, is_read, card_id, created_at)"""

from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class NotificationResponse(BaseModel):
    id : int
    type: str
    content: str
    is_read: bool
    card_id: Optional[int] = None
    created_at:datetime
    class Config:
        from_attributes = True