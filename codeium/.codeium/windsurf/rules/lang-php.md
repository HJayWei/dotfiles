---
trigger: glob
globs: **/*.php
---

# PHP (Laravel) 開發準則

> 適用於 Laravel 11+ 後端 API 開發。
>
> 參考來源：Laravel 官方文件、PHP-FIG PSR 標準、Spatie PHP 開發準則、Laravel Best Practices

---

## 版本要求

- PHP 8.2+（享有 Fibers、enum、readonly properties、intersection types）
- Laravel 11+
- Composer 2.x

---

## 專案結構（遵循 Laravel 慣例）

```
app/
├── Http/
│   ├── Controllers/        ← 控制器（薄，僅處理 HTTP）
│   ├── Requests/           ← Form Request 驗證
│   ├── Resources/          ← API Resource 回應格式化
│   └── Middleware/         ← 中介層
├── Models/                 ← Eloquent 模型
├── Services/               ← 業務邏輯層
├── Repositories/           ← 資料存取層（可選，視複雜度決定）
├── Actions/                ← 單一動作類別（Spatie 風格）
├── Events/                 ← 事件
├── Listeners/              ← 事件監聽器
├── Jobs/                   ← 佇列任務
├── Policies/               ← 授權策略
└── Exceptions/             ← 自定義例外
```

---

## 控制器（Controller）

**控制器保持薄（Thin Controller）**：只負責接收請求、呼叫服務、回傳回應。

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Requests\CreateUserRequest;
use App\Http\Resources\UserResource;
use App\Services\UserService;
use Illuminate\Http\JsonResponse;

class UserController extends Controller
{
    public function __construct(
        private readonly UserService $userService,
    ) {}

    public function store(CreateUserRequest $request): JsonResponse
    {
        $user = $this->userService->create($request->validated());

        return response()->json(
            new UserResource($user),
            201,
        );
    }
}
```

**禁止在控制器中**:
- 直接查詢資料庫（應透過 Service 或 Repository）
- 包含複雜的業務邏輯
- 直接操作 Eloquent Model 的關聯

---

## Form Request 驗證

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CreateUserRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /** @return array<string, array<int, string>> */
    public function rules(): array
    {
        return [
            'name'  => ['required', 'string', 'min:1', 'max:100'],
            'email' => ['required', 'email', 'unique:users,email'],
            'role'  => ['required', 'in:user,admin,moderator'],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'name.required'  => '姓名為必填欄位',
            'email.unique'   => '此電子郵件已被使用',
        ];
    }
}
```

---

## Service 層

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use App\Exceptions\DuplicateEmailException;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function create(array $data): User
    {
        if (User::where('email', $data['email'])->exists()) {
            throw new DuplicateEmailException($data['email']);
        }

        return User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);
    }
}
```

---

## Eloquent 模型

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory;
    use SoftDeletes;

    /** @var list<string> */
    protected $fillable = [
        'user_id',
        'total_amount',
        'status',
    ];

    /** @var array<string, string> */
    protected $casts = [
        'total_amount' => 'decimal:2',
        'status'       => OrderStatus::class,
    ];

    /** 隱藏敏感欄位，防止洩漏 */
    /** @var list<string> */
    protected $hidden = ['deleted_at'];
}
```

**Eloquent 規則**:
- 使用 `$fillable` 而非 `$guarded = []`（明確允許的欄位）
- 使用 `$casts` 自動型別轉換
- 日期欄位使用 `Carbon`（Laravel 自動處理）
- 避免在迴圈中執行查詢（N+1 問題）

---

## N+1 查詢防護

```php
// 禁止（N+1）
$orders = Order::all();
foreach ($orders as $order) {
    echo $order->user->name;  // 每次迴圈都發出一次查詢
}

// 正確（Eager Loading）
$orders = Order::with('user')->get();
foreach ($orders as $order) {
    echo $order->user->name;  // 已預先載入
}

// 在開發環境使用 Laravel Telescope 或以下方式偵測 N+1
// Model::preventLazyLoading(app()->isLocal());
```

---

## API Resource

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'name'       => $this->name,
            'email'      => $this->email,
            'role'       => $this->role,
            'created_at' => $this->created_at->toIso8601String(),
        ];
    }
}
```

---

## 自定義例外

```php
<?php

declare(strict_types=1);

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DuplicateEmailException extends Exception
{
    public function __construct(string $email)
    {
        parent::__construct("電子郵件 {$email} 已被使用");
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json([
            'message' => $this->getMessage(),
            'code'    => 'DUPLICATE_EMAIL',
        ], 422);
    }
}
```

---

## 命名慣例（PSR + Laravel 慣例）

| 類型 | 慣例 | 範例 |
|------|------|------|
| 類別 | `PascalCase` | `UserService` |
| 方法 | `camelCase` | `createUser()` |
| 變數 | `camelCase` | `$currentUser` |
| 屬性（資料庫欄位） | `snake_case` | `created_at` |
| 常數 | `UPPER_SNAKE_CASE` | `const MAX_SIZE = 100` |
| 介面 | `PascalCase` + 後綴 `Interface` | `UserRepositoryInterface` |
| 抽象類別 | `Abstract` 前綴 | `AbstractRepository` |
| 路由名稱 | `kebab-case` 以 `.` 分隔 | `users.store` |

---

## 測試（PHPUnit + Pest）

```php
<?php

declare(strict_types=1);

use App\Models\User;
use App\Services\UserService;

// 使用 Pest（Laravel 推薦，更簡潔）
it('成功建立使用者並回傳使用者物件', function () {
    $service = new UserService();
    $dto = ['name' => '王小明', 'email' => 'wang@example.com', 'password' => 'Password1!'];

    $user = $service->create($dto);

    expect($user)->toBeInstanceOf(User::class)
        ->and($user->email)->toBe('wang@example.com')
        ->and($user->password)->not->toBe('Password1!');  // 應已雜湊
});

it('email 重複時拋出 DuplicateEmailException', function () {
    User::factory()->create(['email' => 'existing@example.com']);

    $service = new UserService();

    expect(fn () => $service->create([
        'name'     => '測試',
        'email'    => 'existing@example.com',
        'password' => 'Password1!',
    ]))->toThrow(\App\Exceptions\DuplicateEmailException::class);
});
```

---

## 程式碼風格工具

```bash
# Laravel Pint（官方 PHP 格式化工具，基於 PHP-CS-Fixer）
./vendor/bin/pint

# PHPStan（靜態分析）
./vendor/bin/phpstan analyse --level=8

# Pest（測試執行）
./vendor/bin/pest --coverage
```

```json
// pint.json
{
    "preset": "laravel",
    "rules": {
        "declare_strict_types": true,
        "ordered_imports": true,
        "no_unused_imports": true
    }
}
```

---

## 必要的安全實踐

- 所有控制器檔案加上 `declare(strict_types=1);`
- 使用 Laravel 的 `$fillable`（禁止 mass assignment 漏洞）
- 密碼必須使用 `Hash::make()`（bcrypt）
- 使用 `Policy` 進行物件層級授權
- 資料庫查詢使用 Eloquent 或 DB::select() 的參數化查詢
- 敏感欄位加入 Model 的 `$hidden` 陣列
