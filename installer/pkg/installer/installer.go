package installer

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/fatih/color"
)

type Installer struct {
	homebrewPrefix string
	homeDir        string
	dotfilesPath   string
}

func NewInstaller() *Installer {
	homeDir := os.Getenv("HOME")
	return &Installer{
		homeDir:      homeDir,
		dotfilesPath: homeDir + "/dotfiles",
	}
}

func (i *Installer) CheckSystem() error {
	if runtime.GOOS != "darwin" {
		return fmt.Errorf("此安裝工具僅支援 macOS 系統")
	}

	color.White("  系統: macOS")
	color.White("  家目錄: %s", i.homeDir)
	color.White("  Dotfiles 路徑: %s", i.dotfilesPath)

	return nil
}

func (i *Installer) runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	return cmd.Run()
}

func (i *Installer) commandExists(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func (i *Installer) findHomebrew() string {
	paths := []string{
		"/opt/homebrew/bin/brew",
		"/usr/local/bin/brew",
		i.homeDir + "/.homebrew/bin/brew",
	}

	for _, path := range paths {
		if _, err := os.Stat(path); err == nil {
			if strings.Contains(path, "/opt/homebrew") {
				return "/opt/homebrew"
			} else if strings.Contains(path, "/usr/local") {
				return "/usr/local"
			} else {
				return i.homeDir + "/.homebrew"
			}
		}
	}

	if i.commandExists("brew") {
		cmd := exec.Command("brew", "--prefix")
		output, err := cmd.Output()
		if err == nil {
			return strings.TrimSpace(string(output))
		}
	}

	return ""
}

func (i *Installer) InstallXcodeTools() error {
	if i.commandExists("xcode-select") {
		cmd := exec.Command("xcode-select", "-p")
		if err := cmd.Run(); err == nil {
			color.White("  Xcode Command Line Tools 已安裝")
			return nil
		}
	}

	color.White("  開始安裝 Xcode Command Line Tools...")
	color.Yellow("  請在彈出的視窗中點擊「安裝」按鈕")
	return i.runCommand("xcode-select", "--install")
}

func (i *Installer) InstallHomebrew() error {
	prefix := i.findHomebrew()
	if prefix != "" {
		i.homebrewPrefix = prefix
		color.White("  Homebrew 已安裝於: %s", prefix)
		return nil
	}

	color.White("  開始安裝 Homebrew...")
	cmd := exec.Command("/bin/bash", "-c", "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("Homebrew 安裝失敗: %w", err)
	}

	prefix = i.findHomebrew()
	if prefix == "" {
		return fmt.Errorf("Homebrew 安裝後仍無法找到")
	}

	i.homebrewPrefix = prefix
	os.Setenv("PATH", prefix+"/bin:"+os.Getenv("PATH"))

	return nil
}

func (i *Installer) InstallBrewPackages() error {
	if i.homebrewPrefix == "" {
		i.homebrewPrefix = i.findHomebrew()
	}

	brewCmd := i.homebrewPrefix + "/bin/brew"
	if !i.commandExists(brewCmd) && !i.commandExists("brew") {
		return fmt.Errorf("找不到 brew 命令")
	}

	color.White("  從 Brewfile 安裝套件...")
	if err := i.runCommand(brewCmd, "bundle", "install", "--file", "Brewfile"); err != nil {
		return fmt.Errorf("安裝 Brewfile 套件失敗: %w", err)
	}

	zinitPath := i.homebrewPrefix + "/opt/zinit/zinit.zsh"
	if _, err := os.Stat(zinitPath); err == nil {
		color.White("  載入 Zinit...")
		os.Setenv("ZINIT_HOME", i.homebrewPrefix+"/opt/zinit")
	}

	return nil
}

func (i *Installer) InstallNerdFonts() error {
	brewCmd := i.homebrewPrefix + "/bin/brew"
	if !i.commandExists(brewCmd) && !i.commandExists("brew") {
		brewCmd = "brew"
	}

	fonts := []string{
		"font-commit-mono-nerd-font",
		"font-fira-code-nerd-font",
		"font-meslo-lg-nerd-font",
		"font-hack-nerd-font",
		"font-maple-mono-normal-nf-cn",
		"font-blex-mono-nerd-font",
	}

	for _, font := range fonts {
		color.White("  安裝字型: %s", font)
		if err := i.runCommand(brewCmd, "install", "--cask", font); err != nil {
			color.Yellow("  警告: 字型 %s 安裝失敗，繼續...", font)
		}
	}

	return nil
}

func (i *Installer) InstallBrewCasks() error {
	brewCmd := i.homebrewPrefix + "/bin/brew"
	if !i.commandExists(brewCmd) && !i.commandExists("brew") {
		brewCmd = "brew"
	}

	color.White("  從 BrewCask 安裝應用程式...")
	if err := i.runCommand(brewCmd, "bundle", "install", "--file", "BrewCask"); err != nil {
		return fmt.Errorf("安裝 BrewCask 應用程式失敗: %w", err)
	}

	return nil
}

func (i *Installer) InitGitSubmodules() error {
	if !i.commandExists("git") {
		return fmt.Errorf("git 未安裝")
	}

	color.White("  初始化 Git Submodules...")
	if err := i.runCommand("git", "submodule", "init"); err != nil {
		return fmt.Errorf("初始化 submodule 失敗: %w", err)
	}

	color.White("  更新 Git Submodules...")
	if err := i.runCommand("git", "submodule", "update", "--init", "--recursive"); err != nil {
		return fmt.Errorf("更新 submodule 失敗: %w", err)
	}

	return nil
}

func (i *Installer) DeployConfigs() error {
	if !i.commandExists("stow") {
		return fmt.Errorf("stow 未安裝，請先安裝 Homebrew 套件")
	}

	configs := []string{
		"alacritty",
		"zsh",
		"git",
		"nvim",
		"bat",
		"docker",
		"espanso",
		"zellij",
		"prettier",
		"ssh",
		"ghostty",
		"codeium",
	}

	for _, config := range configs {
		configPath := i.dotfilesPath + "/" + config
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			color.Yellow("  跳過 %s (目錄不存在)", config)
			continue
		}

		color.White("  部署 %s 配置...", config)
		if err := i.runCommand("stow", config); err != nil {
			color.Yellow("  警告: %s 配置部署失敗，可能已存在: %v", config, err)
		}
	}

	if i.commandExists("bat") {
		color.White("  重建 Bat 快取...")
		i.runCommand("bat", "cache", "--clear")
		i.runCommand("bat", "cache", "--build")
	}

	return nil
}

func (i *Installer) InstallRust() error {
	if i.commandExists("rustc") && i.commandExists("cargo") {
		color.White("  Rust 已安裝")
		return nil
	}

	color.White("  開始安裝 Rust...")
	color.Yellow("  請依照提示完成安裝")

	cmd := exec.Command("/bin/bash", "-c", "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("Rust 安裝失敗: %w", err)
	}

	cargoPath := i.homeDir + "/.cargo/bin"
	os.Setenv("PATH", cargoPath+":"+os.Getenv("PATH"))

	return nil
}

func (i *Installer) CreateProjectDir() error {
	projectDir := i.homeDir + "/Project"

	if _, err := os.Stat(projectDir); err == nil {
		color.White("  專案目錄已存在: %s", projectDir)
		return nil
	}

	color.White("  建立專案目錄: %s", projectDir)
	if err := os.MkdirAll(projectDir, 0755); err != nil {
		return fmt.Errorf("建立專案目錄失敗: %w", err)
	}

	return nil
}
