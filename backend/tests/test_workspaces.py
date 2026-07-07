import pytest

@pytest.mark.asyncio
async def test_워크스페이스_생성(auth_client):
    res = await auth_client.post("/api/v1/workspaces/", json={
        "name": "테스트 워크스페이스",
    })
    assert res.status_code == 201
    assert res.json()["name"] == "테스트 워크스페이스"

@pytest.mark.asyncio
async def test_워크스페이스_목록_조회(auth_client):
    # 워크스페이스 생성
    await auth_client.post("/api/v1/workspaces/", json={
        "name": "워크스페이스1",
    })
    await auth_client.post("/api/v1/workspaces/", json={
        "name": "워크스페이스2",
    })
    # 목록 조회
    res = await auth_client.get("/api/v1/workspaces/")
    assert res.status_code == 200
    assert len(res.json()) == 2

@pytest.mark.asyncio
async def test_워크스페이스_삭제(auth_client):
    # 생성
    res = await auth_client.post("/api/v1/workspaces/", json={
        "name": "삭제할 워크스페이스",
    })
    ws_id = res.json()["id"]
    # 삭제
    res = await auth_client.delete(f"/api/v1/workspaces/{ws_id}")
    assert res.status_code == 204

@pytest.mark.asyncio
async def test_로그인_안하고_워크스페이스_생성_401(client):
    # auth_client가 아닌 일반 client (토큰 없음)
    res = await client.post("/api/v1/workspaces/", json={
        "name": "실패할 워크스페이스",
    })
    assert res.status_code == 401