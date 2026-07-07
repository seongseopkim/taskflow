import pytest
import pytest_asyncio

@pytest_asyncio.fixture
async def board_and_list(auth_client):
    # 워크스페이스 → 보드 → 리스트 생성
    ws = await auth_client.post("/api/v1/workspaces/", json={"name": "카드테스트"})
    board = await auth_client.post(
        f"/api/v1/workspaces/{ws.json()['id']}/boards/",
        json={"name": "보드"},
    )
    lst = await auth_client.post(
        f"/api/v1/boards/{board.json()['id']}/lists",
        json={"title": "할 일"},
    )
    return {"workspace": ws.json(), "board": board.json(), "list": lst.json()}

@pytest.mark.asyncio
async def test_카드_생성(auth_client, board_and_list):
    lst = board_and_list["list"]
    res = await auth_client.post(
        f"/api/v1/lists/{lst['id']}/cards",
        json={"title": "첫 번째 카드"},
    )
    assert res.status_code == 201
    assert res.json()["title"] == "첫 번째 카드"

@pytest.mark.asyncio
async def test_카드_수정(auth_client, board_and_list):
    lst = board_and_list["list"]
    # 카드 생성
    card = await auth_client.post(
        f"/api/v1/lists/{lst['id']}/cards",
        json={"title": "원래 제목"},
    )
    card_id = card.json()["id"]
    # 수정
    res = await auth_client.patch(
        f"/api/v1/cards/{card_id}",
        json={"title": "새 제목"},
    )
    assert res.status_code == 200
    assert res.json()["title"] == "새 제목"

@pytest.mark.asyncio
async def test_카드_이동(auth_client, board_and_list):
    board = board_and_list["board"]
    lst1 = board_and_list["list"]
    # 두 번째 리스트 생성
    lst2 = await auth_client.post(
        f"/api/v1/boards/{board['id']}/lists",
        json={"title": "진행 중"},
    )
    # 카드 생성 (리스트1에)
    card = await auth_client.post(
        f"/api/v1/lists/{lst1['id']}/cards",
        json={"title": "이동할 카드"},
    )
    card_id = card.json()["id"]
    # 리스트2로 이동
    res = await auth_client.patch(
        f"/api/v1/cards/{card_id}/move",
        json={"target_list_id": lst2.json()["id"], "position": 65536.0},
    )
    assert res.status_code == 200
    assert res.json()["list_id"] == lst2.json()["id"]

@pytest.mark.asyncio
async def test_카드_삭제(auth_client, board_and_list):
    lst = board_and_list["list"]
    card = await auth_client.post(
        f"/api/v1/lists/{lst['id']}/cards",
        json={"title": "삭제할 카드"},
    )
    card_id = card.json()["id"]
    res = await auth_client.delete(f"/api/v1/cards/{card_id}")
    assert res.status_code == 204

@pytest.mark.asyncio
async def test_없는_카드_수정_404(auth_client):
    res = await auth_client.patch(
        "/api/v1/cards/99999",
        json={"title": "없는 카드"},
    )
    assert res.status_code == 404