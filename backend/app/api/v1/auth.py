from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserLogin, TokenResponse, RefreshRequest
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_token

router = APIRouter(prefix="/auth", tags=["auth"])

#비동기식SQLAlchemy에서 sql문법 사욧ㅇ하고 나면, 결과 객체를 반환함. 그래서 result라고 변수명을 쓰는거기도 하고 
# 그래서 결과 객체 -> 실제 데이터(실제 객체)로 변환 하는 방법이 필요..?
# result.scalar_one_or_none() => 결과가 1개면 그 객체 반환, 0개면 none 반환
# result.scalars().all() => 결과 전부를 '리스트'로 반환. (목록 조회할 때 쓰기 좋음)
# result.scalar_one() => 결과가 정확히. 1개여야함. 0, 2이상 이면 에러남. 즉, "반드시 있어야 하는 데이터 조회 시"

@router.post("/signup", status_code=201)
async def signup(data: UserCreate, db: AsyncSession = Depends(get_db)):
    # 1. 이메일 중복 체크 (select로 조회)
    # 2. 중복이면 HTTPException(409, "이미 존재하는 이메일")
    # 3. 비밀번호 해싱
    # 4. User 생성 + db.add + await db.flush()
    # 5. 토큰 발급해서 반환
    
    # 비동기식SQLAlchemy 문법
    # result = await db.execute(select(테이블이름).where(조건문))
    result = await db.execute(
        select(User).where(data.email == User.email)
    )
    user = result.scalar_one_or_none()
    if(user != None):
        raise HTTPException(409, "이미 존재하는 이메일")
    
    user = User(email=data.email, 
                name=data.name, 
                hashed_password = hash_password(data.password))
    db.add(user)
    await db.flush()

    return TokenResponse(
        access_token=create_access_token(user.id),
        refresh_token=create_refresh_token(user.id),
        token_type="bearer" #-> 먼뜻인지모름
    )

@router.post("/login")
async def login(data: UserLogin, db: AsyncSession = Depends(get_db)):
    # 1. 이메일로 유저 조회
    # 2. 없거나 비밀번호 틀리면 HTTPException(401)
    # 3. 토큰 발급해서 반환
    result = await db.execute(
        select(User).where(User.email == data.email)
    )

    user = result.scalar_one_or_none()
    # 비밀번호가 틀렸을 때에[ㄴ 401예외처리, 유저가 없거나, 비말번호가 틀렸을 때 전부로 해야함.
    # 그것 뿐만 아니라 hashed_password기준으로 틀렸는지 안틀렸는지를 봐서 검증하는 단계도 필요함.
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(401, "비밀번호가 틀렸습니다")
    
    return TokenResponse(
        access_token = create_access_token(user.id),
        refresh_token = create_refresh_token(user.id),
        token_type = "bearer"
    )

@router.post("/refresh")
async def refresh(data: RefreshRequest):
    # 1. decode_token으로 refresh_token 검증
    # 2. 실패하거나 type이 "refresh"가 아니면 HTTPException(401)
    # 3. 새 access_token 발급해서 반환
    payload = decode_token(data.refresh_token)
    if payload is None or payload["type"] != "refresh":
        raise HTTPException(401, "토큰이 이상합니닼")
    
    user_id = int(payload["sub"])
    return TokenResponse(
        access_token = create_access_token(user_id),
        refresh_token = data.refresh_token,
        token_type = "bearer"
    )