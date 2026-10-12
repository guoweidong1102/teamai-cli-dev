#!/bin/bash
# vault.sh — Obsidian Vault 辅助操作脚本
# 用法:
#   vault.sh status           # 检查 CLI 可用性 + 收件箱概览
#   vault.sh open <相对路径>   # 在 Obsidian 中打开笔记（自动 URL 编码中文路径）
#   vault.sh inbox            # 列出收件箱待整理文件

VAULT="/Users/xiaomidong/Desktop/gwd自动化工作流/gwd-second-brain"
CLI="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"

case "$1" in
  status)
    echo "=== CLI 状态 ==="
    # 注意: CLI 未启用时退出码也是 0，必须检查输出内容
    if "$CLI" --help 2>&1 | grep -q "not enabled"; then
      echo "CLI: 未启用（设置 → 通用 → 高级 → 命令行接口）"
    elif "$CLI" --help 2>&1 | grep -q "unable to find Obsidian"; then
      echo "CLI: 已启用，但 Obsidian 未运行"
    else
      echo "CLI: 已启用"
    fi
    echo ""
    echo "=== 收件箱 ($VAULT/0-inbox) ==="
    count=$(find "$VAULT/0-inbox" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo "待整理笔记: $count 篇"
    find "$VAULT/0-inbox" -type f -name "*.md" 2>/dev/null | head -20
    ;;
  open)
    if [ -z "$2" ]; then
      echo "用法: vault.sh open <vault内相对路径，如 2-areas/笔记.md>" >&2
      exit 1
    fi
    # jq 不一定存在，用 python 做百分号编码（兼容中文）
    ENC=$(/usr/bin/python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$2")
    open "obsidian://open?vault=gwd-second-brain&file=$ENC"
    echo "已在 Obsidian 中打开: $2"
    ;;
  inbox)
    find "$VAULT/0-inbox" -type f -name "*.md" 2>/dev/null
    ;;
  *)
    echo "用法: vault.sh {status|open <相对路径>|inbox}"
    exit 1
    ;;
esac
