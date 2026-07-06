from app.tasks.celery_app import celery_app

# 1. 카드 배정 알림
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_card_assigned_notification(self, assignee_id: int, card_id: int, assigner_name: str):
    # "성섭님이 카드를 당신에게 배정했습니다" 알림
    # 1. 알림 내용 만들기
    noti = assigner_name + "이 카드를 당신에게 배정했습니다"
    # 2. (나중에) DB에 notification 레코드 저장
    # 3. (나중에) WebSocket으로 실시간 전송
    # 지금은 print로 확인만
    print(noti)

# 2. 댓글 알림
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_comment_notification(self, card_owner_id: int, card_id: int, commenter_name: str):
    # "민수님이 카드에 댓글을 남겼습니다" 알림
    noti = commenter_name + "님이 카드에 댓글을 남겼습니다"
    print(noti)


# 3. 이메일 발송 (선택)
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_email_notification(self, to_email: str, subject: str, body: str):
    # 이메일 발송 시도
    # 실패하면 self.retry()로 재시도
    try:
        print("이메일 발송 - notification_tasks.py:28" )
    except Exception as e:
        raise self.retry(exc = e)
