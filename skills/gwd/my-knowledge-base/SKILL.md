---
name: my-knowledge-base
description: 「我的知识库」— 读写用户的 Obsidian 知识库（Vault 路径 /Users/xiaomidong/Desktop/gwd自动化工作流/gwd-second-brain）。当用户提到知识库、Obsidian、笔记、第二大脑，或要求创建/编辑/搜索笔记、整理收件箱（0-inbox）、移动笔记到 PARA 目录、写日记、打开笔记时使用此技能。涵盖 Obsidian CLI 用法与无 CLI 时的文件级降级方案。
agent_created: true
---

# 我的知识库 — Obsidian 笔记读写技能

## 核心信息

- **Vault 路径**: `/Users/xiaomidong/Desktop/gwd自动化工作流/gwd-second-brain`（下称 `$VAULT`）
- **Obsidian 程序**: `/Applications/Obsidian.app`（版本 1.14.4+，官方 CLI 已启用）
- **CLI 二进制**: `/Applications/Obsidian.app/Contents/MacOS/obsidian-cli`（已实测可用）
- **CLI 通信**: Unix socket `~/.obsidian-cli.sock`，需 Obsidian 正在运行

## Vault 目录结构（PARA 方法论）

```
$VAULT/
├── 0-inbox/      # 收件箱：未分类的新笔记，整理时从这里分发
├── 1-projects/   # 项目：有明确目标和截止日期的事项
├── 2-areas/      # 领域：需要长期维护的责任范围
├── 3.resources/  # 资源：未来可能有用的主题资料
├── 4.archives/   # 归档：已完成或不再活跃的内容
├── daily/        # 每日笔记（YYYY-MM-DD.md）
├── templates/    # 模板
└── .obsidian/    # 应用配置目录 —— 禁止改动
```

## 第一步：检测 CLI 可用性

**重要：CLI 未启用/未运行时退出码也可能是 0，必须检查输出内容而非退出码。**

```bash
out=$(/Applications/Obsidian.app/Contents/MacOS/obsidian-cli --help 2>&1)
echo "$out" | grep -q "not enabled" && echo "CLI 未启用" || echo "CLI OK"
```

若提示找不到 Obsidian（socket 不存在），先确认 Obsidian 是否在运行：`pgrep -x Obsidian`。

- **CLI OK** → 优先使用 CLI（见「CLI 模式」），尤其是搜索和移动文件（自动更新双链）。
- **CLI 未启用** → 使用「文件模式」降级方案，并提醒用户：
  > Obsidian CLI 当前未启用。开启方法：打开 Obsidian → 设置 → 通用 → 高级 → 开启「命令行接口」，建议同时点击「安装命令行快捷方式」。CLI 启用后搜索与移动笔记会自动维护双链关系。

## 创建笔记

文件模式（总是可行）：

1. 用 Write 工具写入 `$VAULT/<目录>/<笔记名>.md`，目录名从上面 PARA 结构中选择；不确定归类时放入 `0-inbox/`。
2. 笔记头部写 YAML frontmatter：

```yaml
---
created: YYYY-MM-DD
tags: []
---
```

日期用 `date +%F` 获取，不要自行推算。

3. 正文使用 Markdown。内部链接用 `[[笔记名]]` 双链语法。
4. 路径含中文，shell 命令必须对整个路径加双引号。

CLI 模式等价命令（已实测）：

```bash
OBS="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"
$OBS create path="0-inbox/新笔记.md" content="正文内容"
$OBS read path="0-inbox/新笔记.md"          # 读笔记
$OBS append path="0-inbox/新笔记.md" content="追加内容"   # 追加
```

注意：`content` 中的换行用字面 `\n` 转义（CLI 会解析）；复杂多行内容建议直接用 Write 工具写文件，CLI 只做打开/移动等操作。

## 编辑笔记

1. 先用 Read 工具读取原文件，再用 Edit 工具做精确替换。
2. 保持既有 frontmatter 字段不变，只更新需要修改的值；如修改内容则追加 `updated: YYYY-MM-DD`。
3. 禁止重写整个文件除非用户明确要求。

## 搜索知识库

**CLI 可用时（首选，已实测）**：

```bash
OBS="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"
$OBS search query="关键词"                      # 搜文件名+内容，返回路径列表
$OBS search:context query="关键词"              # 带匹配行上下文
$OBS search query="关键词" path="2-areas" limit=20   # 限定目录
$OBS backlinks path="2-areas/笔记.md" counts    # 反向链接及计数
$OBS unresolved                                 # 未解析的链接
```

**CLI 不可用时降级**：用 Grep 工具在 `$VAULT` 下搜索（pattern + path），或 Glob 工具按文件名查找 `**/*.md`。搜索结果同样有效，只是拿不到链接图信息。

## 整理收件箱（Inbox Triage）

标准流程：

1. **列出收件箱内容**：

```bash
find "$VAULT/0-inbox" -type f -name "*.md" | head -50
```

2. **逐个阅读**（Read 工具），根据内容判断归属：
   - 有明确目标和截止日期 → `1-projects/`
   - 长期维护的主题 → `2-areas/`
   - 参考资料 → `3.resources/`
   - 已完成/过时 → `4.archives/`
   - 日记性质内容 → `daily/`
   - 无法判断 → 留在 `0-inbox/` 并向用户说明

3. **移动文件**：
   - CLI 可用：`$OBS move path="0-inbox/xx.md" to="2-areas/xx.md"`（已实测：自动更新所有完整路径双链）
   - CLI 不可用：`mv "$VAULT/0-inbox/xx.md" "$VAULT/2-areas/xx.md"`，然后检查是否需要修复双链：如果其他笔记用 `[[xx]]` 短链接引用它，短链接不受目录影响、无需修改；只有完整路径链接 `[[0-inbox/xx]]` 才需要 Grep 全库替换。

4. 目标子目录不存在时先 `mkdir -p` 创建。

5. 批量移动前先列出完整清单征得用户确认；每次批量不超过 10 个文件。

## 在 Obsidian 中打开笔记 / 日记

```bash
bash ~/.workbuddy/skills/my-knowledge-base/scripts/vault.sh open "2-areas/笔记.md"
# 或直接：
open "obsidian://open?vault=gwd-second-brain&file=<URL编码后的相对路径>"
```

仅打开笔记时用 URI 即可，无需 CLI。

## 日记（Daily Notes）

日记插件已配置默认目录为 `daily/`（2026-10-12 实测生效），直接用 CLI：

```bash
$OBS daily:append content="内容"     # 追加到 daily/YYYY-MM-DD.md（已实测）
```

若 `daily:append` 结果显示写到根目录（日记配置被重置的迹象），降级方案：

```bash
printf '%s- 内容\n' "$(date +%H:%M) " >> "$VAULT/daily/$(date +%F).md"
```

## 安全边界

- 绝不改动 `$VAULT/.obsidian/` 目录内的任何文件。
- 删除笔记优先用 `$OBS delete path="..."`（实测进系统废纸篓，可恢复）；CLI 不可用时删除前必须征得用户明确确认，且优先建议移入 `4.archives/`。
- 对 Vault 的批量操作（>10 个文件）先展示完整计划再执行。
- 中文路径在所有 shell 命令中必须加双引号。
- CLI 的 `move`/`delete` 会实时改动 Vault，执行前先确认目标路径正确。
