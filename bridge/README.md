# bridge —— 把任意 agent harness 的状态接进锁屏

锁屏只认一份文件契约，所以「接入某个 harness」从来不是改锁屏，而是**让那个 harness 写出这份 JSON**。

```
%LOCALAPPDATA%\CAScreenGuard\agents\<source>[-<id>].json
{ "state": "working" | "waiting", "reason": "turn-end" | "question",
  "since": "<ISO8601 UTC>", "source": "<source>", "version": 1 }
```

本目录提供两件工具，**都不依赖任何第三方 harness 内部实现**：

| 文件 | 作用 | 依赖 |
|---|---|---|
| `cascreenguard-status.ps1` | 写入器：一条命令写一份状态 | 无 |
| `cascreenguard-watch.ps1` + `watch.json` | 通用观察器：靠日志活动时间推断状态 | 无（不需要改对方配置） |

两者都只用 Windows PowerShell 5.1 自带的命令，不需要装任何东西。

## 一、写入器（推荐，最精确）

```powershell
# 开始干活
.\cascreenguard-status.ps1 -State working -Source codex

# 这一轮结束，轮到人看
.\cascreenguard-status.ps1 -State waiting -Reason turn-end -Source codex

# 明确在等人回答（锁屏会显示琥珀色高亮）
.\cascreenguard-status.ps1 -State waiting -Reason question -Source claude-code

# 进程退出时清掉自己的状态，别留一份「永远在跑」
.\cascreenguard-status.ps1 -State none -Source codex
```

同一个 harness 多会话并行时加 `-Id`：

```powershell
.\cascreenguard-status.ps1 -State working -Source opencode -Id $sessionId
```

写入是「临时文件 + 原子替换」，锁屏那边不会读到半个 JSON；失败只返回非零码，不弹窗。

## 二、通用观察器（不用改对方配置）

把要监视的日志路径写进 `watch.json`：

```json
{
  "sources": [
    { "source": "codex",       "path": "%USERPROFILE%\\.codex\\sessions\\*.jsonl", "workingWindowSeconds": 20 },
    { "source": "claude-code", "path": "%USERPROFILE%\\.claude\\projects\\*.jsonl", "workingWindowSeconds": 20 }
  ]
}
```

然后跑（`-Once` 只跑一轮，便于验证）：

```powershell
.\cascreenguard-watch.ps1 -Once
.\cascreenguard-watch.ps1              # 常驻，默认 3 秒一轮
```

判定规则很简单：**最新日志的修改时间在窗口内 = working，超窗 = waiting / turn-end**。

局限要讲清楚：它只知道「还在写」和「不写了」，**分不清「这一轮结束了」和「它在等你回答」**。要精确到后者，用写入器配钩子。

## 三、给具体 harness 配钩子（模板，未在本机验证）

> 下面只是**形态**。装上某个 harness 之后，请先用 `where <exe>` 或卸载登记确认它真的在运行，再把对应片段填进它自己的配置。

**Codex**（`~/.codex/config.toml`）：

```toml
notify = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\路径\\cascreenguard-status.ps1", "-State", "waiting", "-Reason", "turn-end", "-Source", "codex"]
```

注意 `notify` 通常只有一个槽位：如果已有别的值（例如 computer-use），要写一个包装器同时调用两者，别直接覆盖。

**Claude Code**（`~/.claude/settings.json` 的 `hooks`）：`Stop` → `waiting/turn-end`，`Notification` → `waiting/question`。

**opencode / Gemini CLI / Cursor 等**：机制各不相同（插件、事件钩子、会话库），装好之后先看它自己的文档，能拿到「轮次开始/结束」就往写入器上接；拿不到就用第二节的观察器兜底。

## 四、锁屏侧的行为（不需要改）

- 只显示**锁屏开始之后**仍在活动的对话：`working` 一律显示，`waiting` 只显示锁屏之后才开始的；
- 超过 10 分钟没更新的视为过期，整块不显示；
- 多个 source / 多个会话自动汇总成一行（`DSH 等你回答 · 2 个对话 · 3 分钟`）；
- 只显示状态，不显示对话内容、项目名、提示词。

## 五、自检

```powershell
# 写入器：应生成 agents\demo.json
.\cascreenguard-status.ps1 -State working -Source demo
Get-Content "$env:LOCALAPPDATA\CAScreenGuard\agents\demo.json"

# 清理
.\cascreenguard-status.ps1 -State none -Source demo
```
