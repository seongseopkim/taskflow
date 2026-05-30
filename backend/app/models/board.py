from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey

class Board(Base):
    __tablename__ = "boards"

    id = Column(Integer, primary_key=True)
    workspace_id = Column(Integer, ForeignKey("workspaces.id"))
    name = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
