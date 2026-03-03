---
trigger: glob
globs: **/*.py
---

# Python 開發準則

> 適用於 Django、FastAPI、Flask 後端以及資料科學/機器學習專案。
>
> 參考來源：PEP 8、Google Python Style Guide、Meta PyTorch 慣例

---

## 版本與環境管理

- 最低支援 Python 3.11（享有效能提升與更好的錯誤訊息）
- 建議使用 Python 3.12+，禁止 Python 2 相容性程式碼
- 使用 `pyenv` 管理 Python 版本
- 使用 `uv` 或 `Poetry` 管理虛擬環境與依賴

---

## 型別提示（強制要求）

所有函式參數與回傳值必須有型別提示。

```python
from typing import Optional
from collections.abc import Sequence


def get_user_by_id(user_id: str) -> Optional["User"]:
    """依 ID 查詢使用者。"""
    ...


def calculate_total(
    prices: Sequence[float],
    discount_rate: float = 0.0,
) -> float:
    """計算折扣後的總金額。"""
    return sum(prices) * (1 - discount_rate)
```

### Pydantic 模型（推薦用於 API）

```python
from pydantic import BaseModel, EmailStr, field_validator


class CreateUserDto(BaseModel):
    name: str
    email: EmailStr
    age: int

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError("姓名不能為空白")
        return v.strip()
```

---

## 命名慣例（PEP 8）

| 類型 | 慣例 | 範例 |
|------|------|------|
| 模組與套件 | `snake_case` | `user_service.py` |
| 類別 | `PascalCase` | `UserService` |
| 函式、方法、變數 | `snake_case` | `get_user_by_id()` |
| 常數（模組層級） | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT = 3` |
| 私有成員（慣例） | 前綴 `_` | `_validate_email()` |
| 名稱改編（name mangling） | 前綴 `__` | `__hash_password()` |

---

## 匯入排序（isort / ruff 強制執行）

```python
# 1. 標準函式庫
import os
import sys
from datetime import datetime
from typing import Optional

# 2. 第三方套件
import httpx
from fastapi import FastAPI
from pydantic import BaseModel

# 3. 本地模組
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.utils.logger import logger
```

---

## 錯誤處理

### 自定義例外類別

```python
class AppException(Exception):
    def __init__(self, message: str, code: str = "APP_ERROR") -> None:
        super().__init__(message)
        self.code = code


class NotFoundError(AppException):
    def __init__(self, resource: str, identifier: str) -> None:
        super().__init__(f"{resource} (id: {identifier}) 不存在", "NOT_FOUND")


class ValidationError(AppException):
    def __init__(self, message: str, fields: dict | None = None) -> None:
        super().__init__(message, "VALIDATION_ERROR")
        self.fields = fields or {}
```

### 絕對不吞掉例外

```python
# 禁止
try:
    process_order(order)
except Exception:
    pass

# 正確
try:
    process_order(order)
except OrderProcessingError as e:
    logger.error("訂單處理失敗", extra={"order_id": order.id, "error": str(e)})
    raise
except Exception as e:
    logger.exception("未預期的錯誤", extra={"order_id": order.id})
    raise AppException(f"處理訂單 {order.id} 時發生未預期的錯誤") from e
```

---

## 函式設計

```python
# 超過 4 個參數時使用 TypedDict
from typing import TypedDict


class ProcessOrderOptions(TypedDict):
    order_id: str
    user_id: str
    notify_email: bool
    apply_discount: float


def process_order(options: ProcessOrderOptions) -> "OrderResult":
    """處理訂單。"""
    ...


# 偏好純函式（無副作用）
def calculate_discount(price: float, discount_rate: float) -> float:
    if not 0.0 <= discount_rate <= 1.0:
        raise ValueError(f"折扣率必須在 0 到 1 之間，收到: {discount_rate}")
    return price * (1 - discount_rate)
```

---

## 非同步程式設計（asyncio）

```python
import asyncio
import httpx


async def fetch_user(user_id: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"/users/{user_id}")
        response.raise_for_status()
        return response.json()


# 並行執行獨立的非同步操作
async def get_dashboard_data(user_id: str) -> dict:
    user, orders, stats = await asyncio.gather(
        fetch_user(user_id),
        fetch_user_orders(user_id),
        fetch_user_stats(user_id),
    )
    return {"user": user, "orders": orders, "stats": stats}
```

---

## 測試（pytest）

```python
# tests/unit/test_user_service.py
import pytest
from unittest.mock import MagicMock

from app.services.user_service import UserService
from app.exceptions import NotFoundError


@pytest.fixture
def mock_user_repository():
    return MagicMock()


@pytest.fixture
def user_service(mock_user_repository):
    return UserService(repository=mock_user_repository)


class TestUserService:
    def test_find_by_id_returns_user_when_exists(self, user_service, mock_user_repository):
        # Arrange
        expected = {"id": "1", "name": "測試", "email": "test@example.com"}
        mock_user_repository.find_by_id.return_value = expected

        # Act
        result = user_service.find_by_id("1")

        # Assert
        assert result == expected
        mock_user_repository.find_by_id.assert_called_once_with("1")

    def test_find_by_id_raises_not_found_when_missing(self, user_service, mock_user_repository):
        mock_user_repository.find_by_id.return_value = None

        with pytest.raises(NotFoundError):
            user_service.find_by_id("999")
```

### pytest 設定

```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "--strict-markers --tb=short"

[tool.coverage.run]
source = ["app"]
omit = ["tests/*", "**/__init__.py"]

[tool.coverage.report]
fail_under = 70
```

---

## 程式碼品質工具

| 工具 | 用途 | 設定 |
|------|------|------|
| `ruff` | Linting + 匯入排序（速度極快） | `pyproject.toml [tool.ruff]` |
| `black` | 程式碼格式化 | `pyproject.toml [tool.black]` |
| `mypy` | 靜態型別檢查 | `mypy.ini` 或 `pyproject.toml` |
| `pytest` | 測試執行 | `pyproject.toml [tool.pytest]` |
| `pytest-cov` | 覆蓋率報告 | 搭配 pytest 使用 |

```toml
# pyproject.toml
[tool.ruff]
line-length = 120
target-version = "py311"
select = ["E", "F", "W", "I", "N", "UP", "S", "B"]
ignore = ["E501"]

[tool.black]
line-length = 120
target-version = ["py311"]

[tool.mypy]
strict = true
python_version = "3.11"
```

---

## FastAPI 特定準則

```python
from fastapi import APIRouter, Depends, HTTPException, status
from app.dependencies import get_current_user, get_db_session

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/{user_id}", response_model=UserResponse, status_code=status.HTTP_200_OK)
async def get_user(
    user_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> UserResponse:
    """查詢使用者詳細資訊。"""
    service = UserService(db)
    user = await service.find_by_id(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"使用者 {user_id} 不存在",
        )
    return UserResponse.model_validate(user)
```

**FastAPI 規則**:
- 所有路由函式必須指定 `response_model` 和 `status_code`
- 使用 `Depends` 進行依賴注入，便於測試
- 路由函式保持薄（只做請求解析和回應格式化）
- 業務邏輯放在 Service 層
