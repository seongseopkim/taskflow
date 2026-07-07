import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.database import Base, get_db

# 테스트용 DB (실제 DB랑 분리!)
TEST_DB_URL = "mysql+aiomysql://root:password@localhost:3306/taskflow_test"

@pytest_asyncio.fixture
async def db_session():
    # 1. 테스트용 엔진 생성
    engine = create_async_engine(TEST_DB_URL)

    # 2. 테이블 생성
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # 3. 세션 생성
    session_factory = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    session = session_factory()

    yield session  # ← 테스트 실행

    # 4. 정리 (테이블 삭제)
    await session.close()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()

@pytest_asyncio.fixture
async def client(db_session):
    # 테스트용 DB로 교체
    app.dependency_overrides[get_db] = lambda: db_session

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()

@pytest_asyncio.fixture
async def auth_client(client):
    # 회원가입 + 로그인된 클라이언트
    await client.post("/api/v1/auth/signup", json={
        "email": "test@test.com",
        "password": "Test1234!",
        "name": "테스트",
    })
    res = await client.post("/api/v1/auth/login", json={
        "email": "test@test.com",
        "password": "Test1234!",
    })
    token = res.json()["access_token"]
    client.headers["Authorization"] = f"Bearer {token}"
    yield client