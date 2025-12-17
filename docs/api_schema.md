# 身勝手カレンダー - APIスキーマ定義
# Migatte Calendar - API Schema Definition

バックエンド開発用のスキーマ定義です。

## データモデル

### User
| Field | Type | Description |
|-------|------|-------------|
| id | string (PK) | ユーザーID |
| username | string | ユーザー名 |
| email | string | メールアドレス |
| password_hash | string | パスワードハッシュ |
| created_at | datetime | 作成日時 |

### ScheduleEvent
| Field | Type | Description |
|-------|------|-------------|
| id | string (PK) | イベントID |
| user_id | string (FK→User) | ユーザーID |
| title | string | タイトル |
| category | string | カテゴリ（仕事、プライベート等） |
| start_date | datetime | 開始日時 |
| end_date | datetime | 終了日時 |
| is_ai_generated | bool | AI生成フラグ |
| ek_event_id | string? | EventKit ID（iOS連携用） |
| created_at | datetime | 作成日時 |

### UserProfile
| Field | Type | Description |
|-------|------|-------------|
| user_id | string (PK, FK→User) | ユーザーID |
| encoded_preferences | string | LLM用エンコード済みデータ |
| last_updated | datetime | 最終更新日時 |

### TimelinePost
| Field | Type | Description |
|-------|------|-------------|
| id | string (PK) | 投稿ID |
| user_id | string (FK→User) | ユーザーID |
| event_id | string (FK→ScheduleEvent) | イベントID |
| content | string | 投稿内容（匿名化済み） |
| created_at | datetime | 作成日時 |

---

## API エンドポイント

### 認証
| Method | Endpoint | Request | Response |
|--------|----------|---------|----------|
| POST | `/auth/register` | `{username, email, password}` | `{token, user}` |
| POST | `/auth/login` | `{email, password}` | `{token, user}` |

### イベント
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/events` | ユーザーの予定一覧 |
| POST | `/events` | 予定追加 |
| PUT | `/events/{id}` | 予定更新 |
| DELETE | `/events/{id}` | 予定削除 |

### タイムライン
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/timeline` | タイムライン取得 |
| POST | `/timeline` | 投稿追加 |

### プロフィール
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/profile` | プロフィール取得 |
| PUT | `/profile` | プロフィール更新 |

---

## SQLModel サンプルコード

```python
from sqlmodel import SQLModel, Field
from datetime import datetime
from typing import Optional

class User(SQLModel, table=True):
    id: str = Field(primary_key=True)
    username: str
    email: str
    password_hash: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class ScheduleEvent(SQLModel, table=True):
    id: str = Field(primary_key=True)
    user_id: str = Field(foreign_key="user.id")
    title: str
    category: str
    start_date: datetime
    end_date: datetime
    is_ai_generated: bool = False
    ek_event_id: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class UserProfile(SQLModel, table=True):
    user_id: str = Field(primary_key=True, foreign_key="user.id")
    encoded_preferences: str
    last_updated: datetime = Field(default_factory=datetime.utcnow)

class TimelinePost(SQLModel, table=True):
    id: str = Field(primary_key=True)
    user_id: str = Field(foreign_key="user.id")
    event_id: str = Field(foreign_key="scheduleevent.id")
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)
```
