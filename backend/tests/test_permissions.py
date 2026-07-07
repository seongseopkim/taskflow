import pytest

@pytest.mark.asyncio
async def test_로그인_안하면_워크스페이스_접근_불가(client):
    res = await client.get("/api/v1/workspaces/")
    assert res.status_code == 401

@pytest.mark.asyncio
async def test_로그인_안하면_보드_생성_불가(client):
    res = await client.post(
        "/api/v1/workspaces/1/boards/",
        json={"name": "보드"},
    )
    assert res.status_code == 401