#Requires -Version 5.1
<#
.SYNOPSIS
    通用观察器：不需要任何 harness 配合，靠会话日志的活动时间推断状态。

.DESCRIPTION
    适用场景：目标 harness 没有钩子、或你不想改它的配置。
    原理：agent 工作时会持续往会话日志写；日志静下来了，就说明这一轮结束了。

        newest log mtime 在 workingWindowSeconds 之内  → working
        超过这个窗口                                   → waiting / turn-end

    局限（写清楚，别让人误会）：它分不清「这一轮结束等你说话」和「你问了问题、它正在等回答」，
    所以 waiting 的 reason 只能是 turn-end。要精确知道「在等你回答」，得用写钩子的方式
    （cascreenguard-status.ps1 支持 -Reason question）。

    配置文件（默认同目录 watch.json）里每个 source 一条：

        { "source": "codex",
          "path": "%USERPROFILE%\\.codex\\sessions\\*.jsonl",
          "workingWindowSeconds": 20,
          "waitingReason": "turn-end" }

    path 支持 %ENV% 展开；叶子可以用通配符，子目录会自动递归搜索。
    每个 source 的结果写成与 cascreenguard-status.ps1 相同的契约文件。

.PARAMETER ConfigPath
    配置文件路径，默认脚本同目录的 watch.json。

.PARAMETER Once
    只跑一轮就退出（用于验证与自检）。

.PARAMETER IntervalSeconds
    轮询间隔，默认 3 秒。

.PARAMETER Dir
    覆盖状态根目录，默认 %LOCALAPPDATA%\CAScreenGuard。

.EXAMPLE
    .\cascreenguard-watch.ps1 -Once
#>
[CmdletBinding()]
param(
    [string]$ConfigPath = '',
    [switch]$Once,
    [int]$IntervalSeconds = 3,
    [string]$Dir = ''
)

$ErrorActionPreference = 'Stop'

function Get-NewestLog {
    param([string]$Pattern)
    $full = [Environment]::ExpandEnvironmentVariables($Pattern)
    $dir = Split-Path -Parent $full
    $leaf = Split-Path -Leaf $full
    if ([string]::IsNullOrEmpty($dir) -or [string]::IsNullOrEmpty($leaf)) { return $null }
    if (-not (Test-Path -LiteralPath $dir)) { return $null }
    return Get-ChildItem -LiteralPath $dir -Filter $leaf -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

try {
    if ([string]::IsNullOrEmpty($ConfigPath)) { $ConfigPath = Join-Path $PSScriptRoot 'watch.json' }
    if (-not (Test-Path -LiteralPath $ConfigPath)) { exit 0 }

    $cfg = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $sources = @($cfg.sources | Where-Object { $_ -and $_.source -and $_.path })
    if ($sources.Count -eq 0) { exit 0 }

    $writer = Join-Path $PSScriptRoot 'cascreenguard-status.ps1'
    if (-not (Test-Path -LiteralPath $writer)) { exit 0 }

    if ([string]::IsNullOrEmpty($Dir)) { $Dir = Join-Path $env:LOCALAPPDATA 'CAScreenGuard' }

    # 单实例：多开只会有害（重复写同一批文件）
    $mutex = New-Object System.Threading.Mutex($false, 'Local\CAScreenGuardStatusWatch')
    $owned = $false
    try { $owned = $mutex.WaitOne(0) } catch { $owned = $false }
    if (-not $owned) { exit 0 }

    $last = @{}
    try {
        while ($true) {
            foreach ($s in $sources) {
                $item = Get-NewestLog ([string]$s.path)
                if ($null -eq $item) { continue }

                $window = 20
                if ($null -ne $s.workingWindowSeconds) { $window = [double]$s.workingWindowSeconds }
                $age = ((Get-Date) - $item.LastWriteTime).TotalSeconds

                if ($age -le $window) { $st = 'working'; $rs = '' }
                else {
                    $st = 'waiting'
                    $rs = 'turn-end'
                    if ($null -ne $s.waitingReason -and [string]$s.waitingReason) { $rs = [string]$s.waitingReason }
                }

                $key = $st + '|' + $rs
                if ($last.ContainsKey($s.source) -and $last[$s.source] -eq $key) { continue }
                $last[$s.source] = $key

                # 必须拼成一整条字符串并显式加引号：Start-Process -ArgumentList 传数组时不会
                # 给带空格的路径加引号，C:\Finder Folder\... 会被拆成 C:\Finder。
                $line = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -State {1} -Source "{2}"' -f $writer, $st, ([string]$s.source)
                if ($rs) { $line += (' -Reason {0}' -f $rs) }
                # 观察器只能看到「日志不写了」，一律标成 inferred：锁屏不会把它当成「已完成」
                $line += ' -Precision inferred'
                if ($Dir) { $line += (' -Dir "{0}"' -f $Dir) }
                # -WindowStyle Hidden：子进程不弹窗、也不把 PowerShell 横幅打到控制台
                try { $null = Start-Process -FilePath 'powershell.exe' -ArgumentList $line -WindowStyle Hidden -Wait -PassThru } catch { }
            }

            if ($Once) { break }
            Start-Sleep -Seconds ([Math]::Max(1, $IntervalSeconds))
        }
    }
    finally {
        try { if ($owned) { $mutex.ReleaseMutex() } } catch { }
        try { $mutex.Dispose() } catch { }
    }
    exit 0
}
catch {
    exit 1
}
