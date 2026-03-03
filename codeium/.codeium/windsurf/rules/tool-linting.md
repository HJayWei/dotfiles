---
trigger: model_decision
description: Applied when configuring or running ESLint, Prettier, Stylelint, PHPStan, pylint, or other linting and formatting tools
---

# Linting & Formatting 工具設定準則

> 自動化的程式碼品質檢查是最有效率的 Code Review 輔助工具。
>
> 參考來源：ESLint 官方文件、Prettier 官方文件、Google 工程實踐

---

## 工具選擇原則

| 語言 | Linting | Formatting | 型別檢查 |
|------|---------|-----------|---------|
| TypeScript / JavaScript | ESLint | Prettier | TypeScript compiler |
| Python | Ruff（取代 pylint + flake8 + isort） | Black / Ruff format | mypy |
| PHP | PHP-CS-Fixer / Laravel Pint | Laravel Pint | PHPStan |
| CSS / SCSS | Stylelint | Prettier | — |
| JSON / YAML / Markdown | — | Prettier | — |

---

## TypeScript / JavaScript

### ESLint 設定（`eslint.config.mjs`，ESLint v9 flat config）

```javascript
// eslint.config.mjs
import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import prettier from 'eslint-config-prettier';

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  prettier,  // 關閉與 Prettier 衝突的規則
  {
    languageOptions: {
      parserOptions: {
        project: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // TypeScript 嚴格規則
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/explicit-function-return-type': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/await-thenable': 'error',
      '@typescript-eslint/no-misused-promises': 'error',

      // 程式碼品質
      'no-console': 'warn',
      'no-var': 'error',
      'prefer-const': 'error',
      'eqeqeq': ['error', 'always'],
      'no-implicit-coercion': 'error',
      'no-nested-ternary': 'error',
      'no-param-reassign': 'error',

      // 匯入排序
      'sort-imports': ['error', { ignoreDeclarationSort: true }],
    },
  },
  {
    ignores: ['dist/**', 'node_modules/**', 'coverage/**'],
  },
);
```

### Prettier 設定（`.prettierrc`）

```json
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 120,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

### `package.json` 腳本

```json
{
  "scripts": {
    "lint": "eslint . --ext .ts,.tsx,.js,.jsx",
    "lint:fix": "eslint . --ext .ts,.tsx,.js,.jsx --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "type-check": "tsc --noEmit"
  }
}
```

### `.eslintignore`

```
node_modules/
dist/
coverage/
*.min.js
```

---

## Python

### Ruff 設定（`pyproject.toml`）

```toml
[tool.ruff]
target-version = "py311"
line-length = 120
src = ["app", "tests"]

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "N",    # pep8-naming
    "UP",   # pyupgrade
    "S",    # flake8-bandit (安全性)
    "B",    # flake8-bugbear
    "SIM",  # flake8-simplify
    "TCH",  # flake8-type-checking
]
ignore = [
    "S101",  # assert 語句（測試中允許）
]

[tool.ruff.lint.isort]
known-first-party = ["app"]
force-sort-within-sections = true

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
line-ending = "lf"
```

### Black 設定（`pyproject.toml`）

```toml
[tool.black]
line-length = 120
target-version = ["py311"]
include = '\.pyi?$'
extend-exclude = '''
/(
  | dist
  | build
  | migrations
)/
'''
```

### mypy 設定（`pyproject.toml`）

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true
ignore_missing_imports = false

# 第三方套件的型別忽略（如沒有 stubs）
[[tool.mypy.overrides]]
module = ["some_untyped_package.*"]
ignore_missing_imports = true
```

### 執行腳本

```bash
# Lint + format check
ruff check .
ruff format --check .

# 自動修正
ruff check --fix .
ruff format .

# 型別檢查
mypy app/

# 一鍵執行所有檢查
ruff check . && ruff format --check . && mypy app/
```

---

## PHP（Laravel Pint）

### `pint.json`

```json
{
    "preset": "laravel",
    "rules": {
        "declare_strict_types": true,
        "ordered_imports": {
            "sort_algorithm": "alpha"
        },
        "no_unused_imports": true,
        "array_syntax": {
            "syntax": "short"
        },
        "trailing_comma_in_multiline": {
            "elements": ["arrays", "arguments", "parameters"]
        },
        "single_quote": true,
        "not_operator_with_successor_space": true
    }
}
```

### PHPStan 設定（`phpstan.neon`）

```neon
parameters:
    level: 8
    paths:
        - app
        - tests
    excludePaths:
        - app/Http/Controllers/Auth
    checkMissingIterableValueType: false
```

### 執行腳本

```bash
# 格式化
./vendor/bin/pint

# 格式化檢查（CI 使用）
./vendor/bin/pint --test

# 靜態分析
./vendor/bin/phpstan analyse

# 測試
./vendor/bin/pest --coverage
```

---

## CSS / SCSS（Stylelint）

### `.stylelintrc.json`

```json
{
  "extends": [
    "stylelint-config-standard",
    "stylelint-config-prettier"
  ],
  "rules": {
    "color-no-invalid-hex": true,
    "unit-no-unknown": true,
    "property-no-unknown": true,
    "declaration-block-no-duplicate-properties": true,
    "selector-class-pattern": "^[a-z][a-z0-9-]*$",
    "no-descending-specificity": true,
    "color-named": "never",
    "shorthand-property-no-redundant-values": true
  }
}
```

---

## Git Hooks 整合（Husky + lint-staged）

### 設定

```bash
# 安裝
npm install --save-dev husky lint-staged
npx husky init
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": [
      "eslint --fix",
      "prettier --write"
    ],
    "*.{css,scss}": [
      "stylelint --fix",
      "prettier --write"
    ],
    "*.{json,md,yaml,yml}": [
      "prettier --write"
    ]
  }
}
```

```bash
# .husky/pre-commit
#!/usr/bin/env sh
npx lint-staged

# .husky/commit-msg
#!/usr/bin/env sh
npx --no -- commitlint --edit $1
```

### commitlint 設定（`.commitlintrc.json`）

```json
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [
      2,
      "always",
      ["feat", "fix", "refactor", "test", "docs", "chore", "style", "perf", "ci", "build", "revert"]
    ],
    "subject-max-length": [2, "always", 72],
    "subject-empty": [2, "never"],
    "type-empty": [2, "never"]
  }
}
```

---

## CI/CD 整合

### GitHub Actions 工作流程

```yaml
# .github/workflows/quality.yml
name: Code Quality

on: [push, pull_request]

jobs:
  lint-and-type-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'

      - run: npm ci

      - name: ESLint
        run: npm run lint

      - name: Prettier 格式檢查
        run: npm run format:check

      - name: TypeScript 型別檢查
        run: npm run type-check

      - name: 單元測試 + 覆蓋率
        run: npm run test:coverage

      - name: 覆蓋率上傳
        uses: codecov/codecov-action@v4
```

---

## 編輯器設定（VS Code / Windsurf）

### `.vscode/settings.json`（提交至 Git，供團隊共用）

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.organizeImports": "explicit"
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "[python]": {
    "editor.defaultFormatter": "charliermarsh.ruff"
  },
  "files.eol": "\n",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true
}
```

### `.vscode/extensions.json`（推薦套件）

```json
{
  "recommendations": [
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "charliermarsh.ruff",
    "ms-python.python",
    "ms-python.mypy-type-checker",
    "bmewburn.vscode-intelephense-client",
    "bradlc.vscode-tailwindcss",
    "mikestead.dotenv",
    "eamodio.gitlens"
  ]
}
```
