---
trigger: glob
globs: "**/*.vue, **/*.ts, **/*.js"
---

# Vue.js 開發準則

> 適用於 Vue 3 + Composition API、Nuxt 3 等前端專案。
>
> 參考來源：Vue.js Style Guide（Essential + Strongly Recommended）、VueUse、Nuxt 3 官方文件

---

## 版本要求

- Vue 3.4+（Composition API 為主）
- TypeScript 強制（所有 `.vue` 檔案使用 `<script setup lang="ts">`）
- Vite 作為建置工具

---

## 元件風格

### Single File Component（SFC）順序

```vue
<script setup lang="ts">
// 1. 匯入
// 2. Props / Emits 定義
// 3. 響應式狀態
// 4. Computed
// 5. Watchers
// 6. 方法
// 7. 生命週期 hooks
</script>

<template>
  <!-- HTML 模板 -->
</template>

<style scoped>
/* 樣式 */
</style>
```

### 命名慣例

| 類型 | 慣例 | 範例 |
|------|------|------|
| 元件檔名 | `PascalCase.vue` | `UserProfile.vue` |
| 模板中使用元件 | `PascalCase` | `<UserProfile />` |
| Props | `camelCase`（script）/ `kebab-case`（template）| `userName` / `user-name` |
| Emits | `camelCase` | `@updateUser` |
| Composable | `use` 前綴 | `useAuth()`, `useFetch()` |
| 頁面檔案（Nuxt）| `kebab-case` | `user-profile.vue` |

---

## Composition API

### Props 與 Emits（型別安全）

```vue
<script setup lang="ts">
interface Props {
  userId: string;
  userName: string;
  isActive?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  isActive: true,
});

const emit = defineEmits<{
  updateUser: [id: string, name: string];
  delete: [id: string];
}>();
</script>
```

### 響應式狀態

```vue
<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';

// ✅ 優先使用 ref（明確的 .value 存取）
const count = ref(0);
const userName = ref('');

// ✅ 複雜物件使用 reactive
const form = reactive({
  name: '',
  email: '',
  role: 'user' as const,
});

// ✅ Computed（衍生值）
const isFormValid = computed(() =>
  form.name.length > 0 && form.email.includes('@'),
);

// ✅ Watch（副作用）
watch(
  () => form.email,
  (newEmail) => {
    validateEmail(newEmail);
  },
  { debounce: 300 },
);
</script>
```

---

## Composable（可組合函式）

```typescript
// composables/useAuth.ts
import { ref, computed } from 'vue';
import type { User } from '@/types';

export function useAuth() {
  const user = ref<User | null>(null);
  const isAuthenticated = computed(() => user.value !== null);

  async function login(email: string, password: string): Promise<void> {
    const response = await authApi.login({ email, password });
    user.value = response.user;
  }

  function logout(): void {
    user.value = null;
  }

  return {
    user: readonly(user),
    isAuthenticated,
    login,
    logout,
  };
}
```

**Composable 規則**：
- 以 `use` 為前綴
- 回傳 `readonly` 的響應式狀態（防止外部修改）
- 回傳值使用明確的型別定義
- 放在 `composables/` 目錄

---

## 模板準則

```vue
<template>
  <!-- ✅ 使用 v-if + v-else（而非巢狀三元運算子） -->
  <LoadingSpinner v-if="isLoading" />
  <ErrorMessage v-else-if="error" :message="error.message" />
  <UserList v-else :users="users" />

  <!-- ✅ 列表必須使用唯一的 :key -->
  <li v-for="user in users" :key="user.id">
    {{ user.name }}
  </li>

  <!-- ❌ 禁止在同一元素上同時使用 v-if 和 v-for -->
</template>
```

### 模板規則

- `v-for` 必須搭配唯一的 `:key`
- 禁止在同一元素上同時使用 `v-if` 和 `v-for`
- 使用 `PascalCase` 引用元件
- Props 傳遞使用 `kebab-case`
- 事件使用 `@eventName`（非 `v-on:eventName`）

---

## 狀態管理（Pinia）

```typescript
// stores/userStore.ts
import { defineStore } from 'pinia';

interface UserState {
  users: User[];
  currentUser: User | null;
  isLoading: boolean;
}

export const useUserStore = defineStore('user', () => {
  const users = ref<User[]>([]);
  const currentUser = ref<User | null>(null);
  const isLoading = ref(false);

  const activeUsers = computed(() =>
    users.value.filter((u) => u.isActive),
  );

  async function fetchUsers(): Promise<void> {
    isLoading.value = true;
    try {
      users.value = await userApi.getAll();
    } finally {
      isLoading.value = false;
    }
  }

  return {
    users: readonly(users),
    currentUser: readonly(currentUser),
    isLoading: readonly(isLoading),
    activeUsers,
    fetchUsers,
  };
});
```

**Pinia 規則**：
- 使用 Composition API 風格（`setup store`）
- 狀態回傳使用 `readonly()`
- Store 命名：`use{Name}Store`

---

## 測試

### Vitest + Vue Test Utils

```typescript
// components/UserCard.test.ts
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import UserCard from './UserCard.vue';

describe('UserCard', () => {
  it('顯示使用者名稱', () => {
    const wrapper = mount(UserCard, {
      props: { userName: '王小明', userId: '1' },
    });
    expect(wrapper.text()).toContain('王小明');
  });

  it('點擊觸發 delete 事件', async () => {
    const wrapper = mount(UserCard, {
      props: { userName: '王小明', userId: '1' },
    });
    await wrapper.find('[data-testid="delete-btn"]').trigger('click');
    expect(wrapper.emitted('delete')).toHaveLength(1);
    expect(wrapper.emitted('delete')![0]).toEqual(['1']);
  });
});
```

### 測試指令

```bash
# 執行測試
npx vitest run

# 監控模式
npx vitest

# 覆蓋率
npx vitest run --coverage
```

---

## 效能最佳化

- 大型列表使用 `v-memo` 或虛擬捲動（`vue-virtual-scroller`）
- 延遲載入路由：`defineAsyncComponent()` 或 Nuxt 自動路由
- 使用 `shallowRef` / `shallowReactive` 避免深層響應式
- 避免在模板中使用複雜計算（改用 `computed`）

---

## 專案結構（推薦）

```
src/
├── assets/                  ← 靜態資源
├── components/              ← 共用元件
│   ├── ui/                  ← 基礎 UI 元件
│   └── layout/              ← 佈局元件
├── composables/             ← Composable 函式
├── pages/                   ← 頁面元件（或 views/）
├── stores/                  ← Pinia stores
├── services/                ← API 呼叫層
├── types/                   ← TypeScript 型別定義
├── utils/                   ← 工具函式
├── router/                  ← Vue Router 設定
├── App.vue
└── main.ts
```
