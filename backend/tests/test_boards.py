import pytest
import pytest_asyncio   # ← 이거 추가

@pytest_asyncio.fixture
async def workspace(auth_client):
    res = await auth_client.post("/api/v1/workspaces/", json={
        "name": "보드 테스트용",
    })
    return res.json()

@pytest.mark.asyncio
async def test_보드_생성(auth_client, workspace):
    res = await auth_client.post(
        f"/api/v1/workspaces/{workspace['id']}/boards/",
        json={"name": "테스트 보드"},
    )
    assert res.status_code == 201
    assert res.json()["name"] == "테스트 보드"

@pytest.mark.asyncio
async def test_보드_목록_조회(auth_client, workspace):
    await auth_client.post(
        f"/api/v1/workspaces/{workspace['id']}/boards/",
        json={"name": "보드1"},
    )
    await auth_client.post(
        f"/api/v1/workspaces/{workspace['id']}/boards/",
        json={"name": "보드2"},
    )
    res = await auth_client.get(
        f"/api/v1/workspaces/{workspace['id']}/boards/",
    )
    assert res.status_code == 200
    assert len(res.json()) == 2

@pytest.mark.asyncio
async def test_보드_삭제(auth_client, workspace):
    res = await auth_client.post(
        f"/api/v1/workspaces/{workspace['id']}/boards/",
        json={"name": "삭제할 보드"},
    )
    board_id = res.json()["id"]
    res = await auth_client.delete(
        f"/api/v1/workspaces/{workspace['id']}/boards/{board_id}",
    )
    assert res.status_code == 204