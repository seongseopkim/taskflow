from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from app.core.permissions import Role

class WorkspaceCreate(BaseModel):
    # 워크스페이스 생성에 필요한 필드들
    name : str

class WorkspaceUpdate(BaseModel):
    #워크스페이스 수정
    name : Optional[str] = None

class WorkspaceResponse(BaseModel):
    #워크스페이스 조회
    id : int
    owner_id : int
    created_at : datetime
    name : str

    class Config:
        from_attributes = True

class MemberInvite(BaseModel):
    #멤버 초대
    email : str
    role : Role