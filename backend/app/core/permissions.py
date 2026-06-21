# 진짜 말 그대로 권한 체크하는거임. 
# 이 유저가, 이 워크스페이스에서 어떤 role인지를 판별해주는 것이라고 생각하면 될듯.

from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from enum import Enum

from app.database import get_db
from app.models.user import User
from app.models.workspace import WorkspaceMember
from app.dependencies import get_current_user

# 역할 정의
class Role(str, Enum):
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"

# 역할 계층 (숫자가 클수록 권한 높음)
ROLE_HIERARCHY = {Role.OWNER: 3, Role.EDITOR: 2, Role.VIEWER: 1}

def check_permission(required: Role):
    async def _check(
        workspace_id: int,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        
        result = await db.execute(select(WorkspaceMember).where(
            WorkspaceMember.workspace_id == workspace_id, WorkspaceMember.user_id == current_user.id,))
        ####### 진짜중요함. result는 그냥 result라는 객체 타임이라서, 꺼내서 사용해야함.  
        ## 이때, scalar같은거 사용하는거!!!!
        member = result.scalar_one_or_none()

        if member is None:
            raise HTTPException(403, "멤버가 아닙니다")
        if ROLE_HIERARCHY[member.role] < ROLE_HIERARCHY[required]:
            raise HTTPException(403, "권한이 없습니다")
        
        return member
        # 1. workspace_members에서 "이 유저가 이 워크스페이스에 속해있는지" 조회
        #  1-1 : workspace_id로
        # 2. 멤버가 아니면 HTTPException(403, "멤버가 아닙니다")
        # 3. 역할 계층 비교: 유저의 역할 숫자 < 요구 역할 숫자면 403
        # 4. member 반환
    return _check