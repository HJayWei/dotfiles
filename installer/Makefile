.PHONY: help build install run clean test

BINARY_NAME=dotfiles-installer
BUILD_DIR=bin

help:
	@echo "可用的命令："
	@echo "  make build    - 編譯安裝程式"
	@echo "  make install  - 編譯並執行安裝程式"
	@echo "  make run      - 直接執行安裝程式 (不編譯)"
	@echo "  make clean    - 清理編譯檔案"
	@echo "  make test     - 執行測試"

build:
	@echo "正在編譯安裝程式..."
	@mkdir -p $(BUILD_DIR)
	@go build -o $(BUILD_DIR)/$(BINARY_NAME) main.go
	@echo "編譯完成: $(BUILD_DIR)/$(BINARY_NAME)"

install: build
	@echo "開始執行安裝..."
	@./$(BUILD_DIR)/$(BINARY_NAME)

run:
	@echo "直接執行安裝程式..."
	@go run main.go

clean:
	@echo "清理編譯檔案..."
	@rm -rf $(BUILD_DIR)
	@echo "清理完成"

test:
	@echo "執行測試..."
	@go test -v ./...
