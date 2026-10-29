# 桥接层：让别的 harness 也能上报状态

锁屏只读一份文件，不读任何 harness 的内部状态：

```
%LOCALAPPDATA%\CAScreenGuard\agents\<source>[-<id>].json
{ "state": "working" | "waiting", "reason": "turn-end" | "question",
  "since": "<ISO 8601>", "source": "<source>", "version": 1, "precision": "inferred" }
```

`reason` 只在 `waiting` 时有意义；`precision` 缺省表示 `exact`。因此接入一个新的 agent 工具，
不需要改锁屏，只需要让它写出这个文件。

## 锁屏怎么显示

| 文件内容 | 显示 | 样式 |
|---|---|---|
| `working` | `DSH 正在工作 · 已 6 分钟` | 绿点 |
| `waiting` + `question` | `DSH 等你回答 · 3 分钟` | 琥珀色，整块高亮 |
| `waiting` + `turn-end`，`exact` | `DSH 已完成 · 7 分钟前` | 灰点 |
| 任意状态，`precision: inferred` | `Codex 最后活动 · 5 分钟前` | 灰点，不声称完成 |
| 文件缺失、解析失败、`since` 超过 10 分钟 | 不显示 | — |

几条过滤规则：

- 只显示锁屏开始之后仍在活动的会话。锁屏之前就已经 `waiting` 的属于旧消息，不再占屏幕；
  `working` 无论多久都显示，因为它此刻确实在跑。
- 多个来源同时存在时，优先采用 `exact` 的那条来决定文案；数量汇总成 `N 个对话`。
- 标签里的来源名（`DSH`、`Codex`、`Claude`）是产品名，不是对话内容。

## 多来源分行

每个来源一行（`DSH`、`Codex`、`CodeBuddy`……），按紧急程度排序：等你回答的最上，正在工作的次之，
已完成与最后活动的垫底；超过 4 行只保最紧急的。同一来源的多个会话仍汇总成 `N 个对话`。

## 已知接不上：CodeBuddy（实测 2026-10-29）

CodeBuddy 运行期间，`~\.codebuddy\` 下唯一持续变化的文件是插件市场的定时检查
（`plugins\.periodic-marketplace-check` 等），**固定每 60 秒一次**，与 agent 是否在干活无关；
对话/会话文件零写入，`settings.json` 里也没有 hook/notify 类配置项。
观察器若盯这个心跳，CodeBuddy 只要开着就会显示"正在工作"——比不显示更糟，所以默认不接。
等它提供钩子后，按写入器的标准接法接入即可。

## 精度为什么单列一档

通用观察器只能看到"日志不写了"这一个事实。这一轮结束、它在等你回答、进程被杀掉，在这一层无法区分。
所以它写出的 `waiting` 带 `precision: inferred`，锁屏据此把文案降级成"最后活动 N 分钟前"，
而不是替它不确定的事情下结论。

## 两个工具

### `src/bridge/cascreenguard-status.ps1`：写入器

给有钩子的 harness 用，一条命令写一份状态：

```powershell
.\cascreenguard-status.ps1 -State working -Source codex
.\cascreenguard-status.ps1 -State waiting -Reason turn-end -Source codex
.\cascreenguard-status.ps1 -State waiting -Reason question -Source claude-code
.\cascreenguard-status.ps1 -State none -Source codex          # 退出时清掉
.\cascreenguard-status.ps1 -State waiting -Source aider -Id session-7
```

参数：`-State working|waiting|none`、`-Reason ''|turn-end|question`、`-Source`、`-Id`、`-Dir`、
`-Precision exact|inferred`。写入是"临时文件 + 替换"，读的一方永远看不到半个 JSON；
状态没变化就不写盘。失败只返回非零码，不弹窗。

### `src/bridge/cascreenguard-watch.ps1`：通用观察器

不改对方配置，靠会话日志的修改时间推断：最新日志在窗口内算 `working`，超出算 `waiting`，
并自动标成 `inferred`。

```powershell
# src\bridge\watch.json
{
  "sources": [
    { "source": "codex",       "path": "%USERPROFILE%\\.codex\\sessions\\*.jsonl", "workingWindowSeconds": 20 },
    { "source": "claude-code", "path": "%USERPROFILE%\\.claude\\projects\\*.jsonl", "workingWindowSeconds": 20 }
  ]
}
```

```powershell
.\cascreenguard-watch.ps1 -Once     # 跑一轮就退出，便于验证
.\cascreenguard-watch.ps1           # 常驻，默认 3 秒一轮
```

`path` 支持 `%ENV%` 展开，叶子可以带通配符，子目录会递归搜索。带单实例互斥体，重复启动会直接退出。
仓库里那份 `watch.json` 默认是空数组，不监视任何东西。

## 各 harness 的接法（模板，未在本机验证）

下面是形态，不是即用配置。装好某个 harness 之后，先确认它真的在运行（`where <exe>` 或看卸载登记），
再按它自己的文档填进去。

- **Codex**：`~\.codex\config.toml` 里的 `notify` 会在回合结束时调用一个程序。`notify` 通常只有一个槽位，
  如果已经有值（例如 computer-use），要写个包装器同时调用两边，不要直接覆盖。它只在回合结束时触发，
  所以只能给出 `waiting`。
- **Claude Code**：`~\.claude\settings.json` 的 `hooks`：`Stop` 事件对应 `waiting/turn-end`，
  `Notification` 事件对应 `waiting/question`。
- **opencode / Gemini CLI / Cursor 等**：各自的插件或事件机制不同。能拿到"回合开始/结束"就接写入器；
  拿不到就用观察器。

## DeepSeek Harness 用户

不用碰这两个脚本。装配套插件即可，它会按会话写 `agents\<id>.json`：

```powershell
dsh plugin --profile desktop add dsh-get-session-status
```

插件仓库：<https://github.com/Conste11ation117/dsh-get-session-status>

## 隐私边界

写进去的只有状态和时间戳。不要往这些文件里加提示词、回复、项目名、路径或任何能从屏幕上读出对话内容的
东西——锁屏恰恰是给"路过的人"看的。
