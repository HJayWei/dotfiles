# Go 安裝工具使用說明

這是使用 Go 語言重寫的 macOS 開發環境自動化安裝工具，提供更好的錯誤處理、進度顯示和互動體驗。

## 特點

- **跨平台檢查**: 自動驗證是否在 macOS 系統上執行
- **智能偵測**: 自動偵測已安裝的工具，避免重複安裝
- **錯誤處理**: 提供詳細的錯誤訊息，失敗時可選擇繼續或中斷
- **彩色輸出**: 使用顏色區分不同類型的訊息
- **互動式安裝**: 關鍵步驟需要使用者確認

## 前置需求

- macOS 系統
- Go 1.23 或更高版本（如果要從原始碼執行）

## 使用方法

### 方法一：使用 Makefile（推薦）

```bash
# 查看可用命令
make help

# 編譯安裝程式
make build

# 編譯並執行安裝
make install

# 直接執行（不編譯）
make run

# 清理編譯檔案
make clean
```

### 方法二：直接使用 Go

```bash
# 執行安裝（不編譯）
go run main.go

# 編譯後執行
go build -o bin/dotfiles-installer main.go
./bin/dotfiles-installer
```

### 方法三：使用編譯好的執行檔

```bash
# 編譯
go build -o dotfiles-installer main.go

# 執行
./dotfiles-installer
```

## 安裝流程

程式會依序執行以下步驟：

1. **檢查系統環境**
   - 驗證作業系統為 macOS
   - 顯示系統資訊和路徑

2. **安裝 Xcode Command Line Tools**
   - 檢查是否已安裝
   - 未安裝則啟動安裝程序

3. **安裝 Homebrew**
   - 自動偵測現有安裝
   - 支援 Apple Silicon 和 Intel Mac
   - 自動設定環境變數

4. **安裝命令列工具 (Brewfile)**
   - 從 `Brewfile` 批次安裝工具
   - 載入 Zinit（如果可用）

5. **安裝 Nerd Fonts**
   - 安裝 6 種常用的 Nerd Font
   - 字型安裝失敗不會中斷流程

6. **安裝 GUI 應用程式 (BrewCask)**
   - 從 `BrewCask` 批次安裝應用程式

7. **初始化 Git Submodules**
   - 初始化並更新 Neovim 配置

8. **部署配置檔案 (Stow)**
   - 使用 GNU Stow 建立符號連結
   - 自動跳過不存在的配置
   - 衝突時顯示警告但繼續執行

9. **安裝 Rust**
   - 檢查是否已安裝
   - 使用 rustup 安裝最新穩定版

10. **建立專案目錄**
    - 建立 `~/Project` 目錄

## 錯誤處理

- 每個步驟失敗時會顯示錯誤訊息
- 程式會詢問是否繼續執行下一步
- 輸入 `y` 或 `Y` 繼續，其他任何輸入則中斷

## 與 Shell 腳本的差異

### 優勢

1. **更好的錯誤處理**
   - Shell 腳本: 錯誤可能被忽略
   - Go 工具: 明確的錯誤處理和回報

2. **互動式體驗**
   - Shell 腳本: 一路執行到底
   - Go 工具: 失敗時可選擇繼續或停止

3. **智能偵測**
   - Shell 腳本: 簡單的條件判斷
   - Go 工具: 完整的環境偵測邏輯

4. **彩色輸出**
   - Shell 腳本: 純文字
   - Go 工具: 使用顏色區分訊息類型

5. **跨平台潛力**
   - Shell 腳本: 僅限 macOS/Linux
   - Go 工具: 可擴展到其他平台

### 功能對等性

| 功能 | Shell 腳本 | Go 工具 |
|------|-----------|---------|
| Xcode Tools 安裝 | ✓ | ✓ |
| Homebrew 安裝 | ✓ | ✓ |
| Brewfile 安裝 | ✓ | ✓ |
| Nerd Fonts 安裝 | ✓ | ✓ |
| BrewCask 安裝 | ✓ | ✓ |
| Git Submodule | ✓ | ✓ |
| Stow 部署 | ✓ | ✓ |
| Rust 安裝 | ✓ | ✓ |
| 專案目錄建立 | ✓ | ✓ |
| 錯誤處理 | 基本 | 完整 |
| 互動式選擇 | ✗ | ✓ |

## 專案結構

```
dotfiles/
└── installer/                 # Go 安裝工具目錄
    ├── main.go                # 主程式入口
    ├── go.mod                 # Go 模組定義
    ├── Makefile               # 編譯腳本
    ├── README.md              # 本文檔
    ├── pkg/
    │   └── installer/
    │       └── installer.go   # 安裝邏輯實作
    └── bin/                   # 編譯輸出目錄（自動生成）
        └── dotfiles-installer # 編譯後的執行檔
```

## 依賴套件

- `github.com/fatih/color`: 彩色終端輸出
- `github.com/schollz/progressbar/v3`: 進度條顯示（預留）

## 開發指南

### 新增安裝步驟

1. 在 `pkg/installer/installer.go` 中新增方法：

```go
func (i *Installer) InstallNewTool() error {
    // 實作安裝邏輯
    return nil
}
```

2. 在 `main.go` 的 `steps` 陣列中新增步驟：

```go
{"安裝新工具", inst.InstallNewTool},
```

### 修改安裝順序

編輯 `main.go` 中的 `steps` 陣列順序。

### 自訂輸出訊息

使用 `color` 套件的函式：
- `color.Green()`: 成功訊息
- `color.Yellow()`: 警告訊息
- `color.Red()`: 錯誤訊息
- `color.White()`: 一般資訊
- `color.Cyan()`: 標題

## 疑難排解

### 編譯錯誤

```bash
# 清理並重新下載依賴
go clean -modcache
go mod tidy
go mod download
```

### 執行權限問題

```bash
chmod +x bin/dotfiles-installer
```

### Homebrew 找不到

確保 Homebrew 已正確安裝：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 未來計畫

- [ ] 新增進度條顯示
- [ ] 支援配置檔案選擇性安裝
- [ ] 新增 dry-run 模式（僅顯示將執行的步驟）
- [ ] 新增解除安裝功能
- [ ] 支援配置備份與還原
- [ ] 新增單元測試
- [ ] CI/CD 整合

## 貢獻

歡迎提交 Issue 或 Pull Request！

## 授權

本專案供個人使用，請根據需求自行調整。
