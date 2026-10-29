#Requires -Version 5.1
<#
.SYNOPSIS
    把任意 agent harness 的会话状态写成 CAScreenGuard 锁屏可读的 JSON。

.DESCRIPTION
    锁屏只认这一份契约，不认任何 harness 的内部细节：

        %LOCALAPPDATA%\CAScreenGuard\agents\<source>[-<id>].json
        { "state": "working" | "waiting", "reason": "turn-end" | "question",
          "since": "<ISO8601 UTC>", "source": "<source>", "version": 1 }

    用法（在 harness 的钩子里调一行）：

        cascreenguard-status.ps1 -State working   -Source codex
        cascreenguard-status.ps1 -State waiting   -Reason turn-end -Source codex
        cascreenguard-status.ps1 -State waiting   -Reason question -Source claude-code
        cascreenguard-status.ps1 -State none      -Source codex     # 进程退出时清掉自己的状态

    规矩：
      * 只写状态，不写对话内容、项目名、提示词 —— 锁屏是给路过的人看的；
      * 写入是「临时文件 + 替换」，读端永远不会看到半个 JSON；
      * 失败不弹窗、不刷屏，只返回非零退出码，钩子上下文里不打扰用户。

.PARAMETER State
    working = 正在跑；waiting = 这一轮结束/在等人回答；none = 删除本 source 的状态文件。

.PARAMETER Reason
    waiting 时附带的原因：turn-end（这一轮正常结束）、question（明确在等你回答）。

.PARAMETER Source
    上报方名字，用于区分来源与文件名，例如 codex / claude-code / opencode / aider。

.PARAMETER Id
    可选的会话标识。同一个 source 多会话并行时用它区分；不给则一个 source 一份文件。

.PARAMETER Dir
    覆盖状态根目录，默认 %LOCALAPPDATA%\CAScreenGuard。

.EXAMPLE
    .\cascreenguard-status.ps1 -State working -Source codex

.EXAMPLE
    .\cascreenguard-status.ps1 -State none -Source codex
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('working', 'waiting', 'none')]
    [string]$State,

    [ValidateSet('', 'turn-end', 'question')]
    [string]$Reason = '',

    [string]$Source = 'external',
    [string]$Id = '',
    [string]$Dir = '',

    # exact    = 调用方真的知道状态（有钩子，能区分「在跑 / 等你回答 / 这一轮结束」）
    # inferred = 调用方只是猜的（例如靠日志活动时间推断），锁屏会把文案降级为「最后活动」
    [ValidateSet('exact', 'inferred')]
    [string]$Precision = 'exact'
)

function ConvertTo-SafeName([string]$text) {
    $s = ($text -replace '[^A-Za-z0-9_-]', '_')
    if ([string]::IsNullOrEmpty($s)) { $s = 'external' }
    return $s
}

try {
    if ([string]::IsNullOrEmpty($Dir)) { $Dir = Join-Path $env:LOCALAPPDATA 'CAScreenGuard' }
    $agents = Join-Path $Dir 'agents'

    $name = ConvertTo-SafeName $Source
    if (-not [string]::IsNullOrEmpty($Id)) { $name = $name + '-' + (ConvertTo-SafeName $Id) }
    $file = Join-Path $agents ($name + '.json')

    if ($State -eq 'none') {
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force -ErrorAction Stop }
        exit 0
    }

    if (-not (Test-Path -LiteralPath $agents)) {
        $null = New-Item -ItemType Directory -Path $agents -Force -ErrorAction Stop
    }

    $payload = [ordered]@{
        state   = $State
        since   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        source  = $Source
        version = 1
    }
    if (-not [string]::IsNullOrEmpty($Reason)) { $payload['reason'] = $Reason }
    # 只在「猜的」时候写这个字段：老格式（无此字段）= exact，向后兼容
    if ($Precision -eq 'inferred') { $payload['precision'] = 'inferred' }
    $json = ($payload | ConvertTo-Json -Compress -Depth 4)

    $tmp = $file + '.tmp'
    [System.IO.File]::WriteAllText($tmp, $json, (New-Object System.Text.UTF8Encoding($false)))

    if (Test-Path -LiteralPath $file) {
        # 先试原子替换；文件系统不支持（或跨卷）时退回删除再移动
        try { [System.IO.File]::Replace($tmp, $file, $null); exit 0 } catch { }
        try { Remove-Item -LiteralPath $file -Force -ErrorAction Stop } catch { }
    }
    Move-Item -LiteralPath $tmp -Destination $file -Force -ErrorAction Stop
    exit 0
}
catch {
    # 钩子上下文：不弹窗、不打印，留给调用方一个非零码就够了
    exit 1
}
