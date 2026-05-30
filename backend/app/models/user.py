from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False )
    hashed_password = Column(String(255), nullable=False)
    name = Column(String(127), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())


