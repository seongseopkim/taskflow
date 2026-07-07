import pytest

# ── 회원가입 ──

@pytest.mark.asyncio
async def test_회원가입_성공(client):
    res = await client.post("/api/v1/auth/signup", json={
        "email": "new@test.com",
        "password": "Test1234!",
        "name": "새유저",
    })
    assert res.status_code == 201
    data = res.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"

@pytest.mark.asyncio
async def test_중복_이메일_가입_409(client):
    # 첫 번째 가입
    await client.post("/api/v1/auth/signup", json={
        "email": "dup@test.com",
        "password": "Test1234!",
        "name": "유저1",
    })
    # 같은 이메일로 다시 가입
    res = await client.post("/api/v1/auth/signup", json={
        "email": "dup@test.com",
        "password": "Test1234!",
        "name": "유저2",
    })
    assert res.status_code == 409

@pytest.mark.asyncio
async def test_빈_이메일_가입_422(client):
    res = await client.post("/api/v1/auth/signup", json={
        "password": "Test1234!",
        "name": "유저",
    })
    assert res.status_code == 422

# ── 로그인 ──

@pytest.mark.asyncio
async def test_로그인_성공(client):
    # 먼저 가입
    await client.post("/api/v1/auth/signup", json={
        "email": "login@test.com",
        "password": "Test1234!",
        "name": "유저",
    })
    # 로그인
    res = await client.post("/api/v1/auth/login", json={
        "email": "login@test.com",
        "password": "Test1234!",
    })
    assert res.status_code == 200
    assert "access_token" in res.json()

@pytest.mark.asyncio
async def test_잘못된_비밀번호_401(client):
    await client.post("/api/v1/auth/signup", json={
        "email": "wrong@test.com",
        "password": "Test1234!",
        "name": "유저",
    })
    res = await client.post("/api/v1/auth/login", json={
        "email": "wrong@test.com",
        "password": "WrongPass!",
    })
    assert res.status_code == 401

@pytest.mark.asyncio
async def test_존재하지_않는_이메일_401(client):
    res = await client.post("/api/v1/auth/login", json={
        "email": "nobody@test.com",
        "password": "Test1234!",
    })
    assert res.status_code == 401

# ── 토큰 재발급 ──

@pytest.mark.asyncio
async def test_토큰_재발급_성공(client):
    res = await client.post("/api/v1/auth/signup", json={
        "email": "refresh@test.com",
        "password": "Test1234!",
        "name": "유저",
    })
    refresh_token = res.json()["refresh_token"]

    res = await client.post("/api/v1/auth/refresh", json={
        "refresh_token": refresh_token,
    })
    assert res.status_code == 200
    assert "access_token" in res.json()

@pytest.mark.asyncio
async def test_잘못된_리프레시_토큰_401(client):
    res = await client.post("/api/v1/auth/refresh", json={
        "refresh_token": "invalid_token",
    })
    assert res.status_code == 401