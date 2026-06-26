from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.workspace import Workspace, WorkspaceMember
from app.schemas.workspace import WorkspaceCreate, WorkspaceUpdate, WorkspaceResponse, MemberInvite
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role

router = APIRouter(prefix="/workspaces", tags=["workspaces"])

# 1. 내 워크스페이스 목록 조회
@router.get("/")
async def get_workspaces(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # workspace_members에서 내가 속한 workspace_id들을 조회
    # 그 workspace_id로 workspaces 조회
    
    result = await db.execute(select(Workspace).join(WorkspaceMember, 
                                               Workspace.id == WorkspaceMember.workspace_id)
                                               .where(WorkspaceMember.user_id == current_user.id))
    workspaces = result.scalars().all()
    
    return [WorkspaceResponse.model_validate(ws) for ws in workspaces]
# 2. 워크스페이스 생성
@router.post("/", status_code=201)
async def create_workspace(
    data: WorkspaceCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    workspace = Workspace(name = data.name, owner_id = current_user.id)

    db.add(workspace)
    await db.flush()

    workspacemember = WorkspaceMember(user_id = current_user.id, workspace_id = workspace.id, role = "owner", )
    db.add(workspacemember)

    await db.flush()
    return WorkspaceResponse(
        id= workspace.id,
        owner_id = workspace.owner_id,
        created_at = workspace.created_at,
        name = workspace.name
    )
    # 1. Workspace 생성 (owner_id = current_user.id)
    # 2. WorkspaceMember도 생성 (role = "owner")
    # 3. 둘 다 db.add + flush
    # 4. WorkspaceResponse 반환
    

# 3. 워크스페이스 삭제 (owner만)
@router.delete("/{workspace_id}", status_code=204)
async def delete_workspace(
    workspace_id: int,
    member=Depends(check_permission(Role.OWNER)),
    db: AsyncSession = Depends(get_db),
):
    # workspace 조회 → 삭제
    workspace = await db.get(Workspace, workspace_id)

    if not workspace :
        raise HTTPException(404, "워크스페이스를 찾을 수 없습니다" )
    
    await db.delete(workspace)
    await db.flush()

# 4. 멤버 초대 (owner만)
@router.post("/{workspace_id}/members", status_code=201)
async def invite_member(
    workspace_id: int,
    data: MemberInvite,
    member=Depends(check_permission(Role.OWNER)),
    db: AsyncSession = Depends(get_db),
):
    # 1. email로 유저 조회 (없으면 404)

    result = await db.execute(
        select(User).where(User.email == data.email)
    )

    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(404, "유저를 찾을 수 없습니다")
    
    # 2. 이미 멤버인지 확인 (이미면 409)
    
    result = await db.execute(
        select(WorkspaceMember).where(WorkspaceMember.user_id == user.id, WorkspaceMember.workspace_id == workspace_id)
        #email로 유저 조회할때 알아낸 id랑 workspacemember의 user_id를 비교함
        )
    workspaceMember = result.scalar_one_or_none()
    if workspaceMember:
        raise HTTPException(409 ,"이미 멤버인 유저입니다")
    # 3. WorkspaceMember 생성
    new_member = WorkspaceMember(user_id = user.id,
                                  workspace_id = workspace_id,
                                  role = data.role)
    db.add(new_member)
    await db.flush()