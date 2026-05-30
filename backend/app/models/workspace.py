from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey,Enum,UniqueConstraint
class Workspace(Base):
    __tablename__ = "workspaces"

    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    owner_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


class WorkspaceMember(Base):
    __tablename__ = "workspace_members"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    workspace_id = Column(Integer, ForeignKey("workspaces.id"))
    # ENUM을 활용해서 정해진 값만 들어갈 수 있게.
    role = Column(Enum("owner", "editor", "viewer"), default="viewer")
    invited_at = Column(DateTime, default=func.now())
    #UNIQUE -> 한 워크스페이스에는 동일한 user_id가 다시 초대될 수 없게. 
    __table_args__ =(
        UniqueConstraint("user_id", "workspace_id"),
    )