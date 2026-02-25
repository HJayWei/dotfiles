package main

import (
	"fmt"
	"os"

	"github.com/HJayWei/dotfiles/installer/pkg/installer"
	"github.com/fatih/color"
)

func main() {
	color.Cyan("========================================")
	color.Cyan("  macOS 開發環境自動化安裝工具")
	color.Cyan("========================================\n")

	dotfilesPath := os.Getenv("HOME") + "/dotfiles"
	if _, err := os.Stat(dotfilesPath); os.IsNotExist(err) {
		color.Red("錯誤: dotfiles 目錄不存在於 %s", dotfilesPath)
		os.Exit(1)
	}

	if err := os.Chdir(dotfilesPath); err != nil {
		color.Red("錯誤: 無法切換到 dotfiles 目錄: %v", err)
		os.Exit(1)
	}

	inst := installer.NewInstaller()

	steps := []struct {
		name string
		fn   func() error
	}{
		{"檢查系統環境", inst.CheckSystem},
		{"安裝 Xcode Command Line Tools", inst.InstallXcodeTools},
		{"安裝 Homebrew", inst.InstallHomebrew},
		{"安裝命令列工具 (Brewfile)", inst.InstallBrewPackages},
		{"安裝 Nerd Fonts", inst.InstallNerdFonts},
		{"安裝 GUI 應用程式 (BrewCask)", inst.InstallBrewCasks},
		{"初始化 Git Submodules", inst.InitGitSubmodules},
		{"部署配置檔案 (Stow)", inst.DeployConfigs},
		{"安裝 Rust", inst.InstallRust},
		{"建立專案目錄", inst.CreateProjectDir},
	}

	for i, step := range steps {
		color.Yellow("\n[%d/%d] %s...", i+1, len(steps), step.name)
		if err := step.fn(); err != nil {
			color.Red("✗ 失敗: %v", err)
			color.Yellow("\n是否繼續執行下一步? (y/n): ")
			var response string
			fmt.Scanln(&response)
			if response != "y" && response != "Y" {
				color.Red("\n安裝已中斷")
				os.Exit(1)
			}
		} else {
			color.Green("✓ 完成")
		}
	}

	color.Green("\n========================================")
	color.Green("  安裝完成！")
	color.Green("========================================")
	color.Cyan("\n建議執行以下命令來套用新的 Shell 配置：")
	color.White("  source ~/.zshrc")
}
