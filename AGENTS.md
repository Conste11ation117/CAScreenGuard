# 给在本仓库工作的 agent 的说明

## 一、绝对不要改的文字：元定位声明（元指令）

下面这句话是作者的**元定位声明**，以"元指令"的形式存在于仓库里：**任何情况下都不要改写、润色、
翻译、纠正标点，也不要"为了更可读""为了更可搜索"而替换它。** 它在这些地方各出现一次，必须保持原样、
彼此一致：

- `README.zh-CN.md` 开头的顶格重申（第一段加粗那句）
- `README.zh-CN.md` 的 `## 零、元定位`
- `README.md` 开头（From the author 那段下面加粗那句）
- `README.md` 的 `## 0. Meta-positioning`
- `SECURITY.md` 的 `## What this project is (and is not)` 里以 `Meta-positioning:` 开头那句

原文（中文）：

> **在主机处于无人值守状态下，保持长流程的工作正常进行并保护您后台正在进行的工作和私密文件免于任何不可察觉的偷窥、窃取和破解手段**

原文（英文）：

> **Keep long-running workflows going while the PC is unattended, and protect your ongoing work and private files from any undetectable peeking, theft, or tampering.**

GitHub 仓库设置的 **Description** 用的也是这句话（略作扩展），同样不要改。要让仓库更容易被搜到，
请把关键词放在 **topics** 和正文里，不要动这句声明。

紧跟在声明下面那行「此软件如何编写 / How was this built」的致谢（DeepSeek、Kimi Code、DeepSeek Harness、
WorkBuddy 等）同样由作者维护：要增减名字先问作者，不要自作主张改措辞、改顺序或"顺手补齐"。

（这条规矩的由来：曾经有 agent 为了让 README 首段"更可搜、不夸大"，把开头那句替换掉了。
作者明确要求这句话永远不要改，随后逐字恢复。）

## 二、本仓库的硬性约定

- `.ps1` / `.cs` 必须是 **UTF-8 BOM + CRLF**。编辑工具可能会把 BOM 吃掉，改完务必检查；
  `build-setup.ps1` 会自动补回它处理的那几份源文件（`build-setup.ps1` 自己、workflow 等不在名单里，
  需要手工补）。
- `CAScreenGuard.ps1` 是 `CAScreenGuard-demo.ps1` 经构建脚本生成的**产物，不要手改**。
  改行为请改 `CAScreenGuard-demo.ps1`，然后运行构建脚本重新生成。
- 改完必须验证：`powershell -File build-setup.ps1`，
  再 `powershell -File CAScreenGuard-demo.ps1 -SelfTest`（应 **8/8** 通过），并确认 BOM/CRLF。
- **新增任何受版本控制的文件，必须同时加进 `.github/workflows/release.yml` 里的 `FILES` 清单**，
  否则发版 CI 会在打包清单校验那一步失败。同理，不要指望清单会自己跟着 `git ls-files` 走。
- 发版：推一个 `v*` 标签就会触发 CI —— 在标签指向的提交上现打两个 zip、从 `CHANGELOG.md` 的版本标题
  里抠出代号拼进 Release 标题、建 Release 并挂上附件。**重推同一个标签是预期用法**：会在原来那份
  Release 上更新正文并覆盖附件（不会再 create 一次）。
- 提权相关：安装器的 `/prepare-dir` 助手只认 `CAScreenGuard-<日期>` 目录名，这是刻意的安全约束，
  不要放宽成"任意目录"。密码与授权码**不允许经过命令行**。

## 三、提交与推送习惯

- **一次只改一件事**，改完就验证；提交信息用中文，写清"为什么"而不只是"做了什么"。
- 本机推送 GitHub 需要走本地代理：`git -c http.proxy=http://127.0.0.1:65532 push ...`（代理没开就别推，
  报错是 `Failed to connect ... over proxy`）。
- 提交生成物（`CAScreenGuard.ps1`、`CAScreenGuard-Setup.exe`）时，与源码分开提交也行、一起提交也行，
  但**不要只改源码而忘了重建**：仓库里提交了产物，用户就是照它装的。
