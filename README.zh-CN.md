<div align="center">

<img src="Assets/SakuraLogo.png" width="160" alt="Sakura Switch">

# 🌸 Sakura Switch

### 原生 macOS 版 Nintendo Switch 工具箱

<p>
  <img src="https://img.shields.io/badge/macOS-15%2B-black?logo=apple" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/License-PolyForm%20Noncommercial-ff69b4" alt="PolyForm Noncommercial License">
  <img src="https://img.shields.io/github/v/release/borisovinfra/Sakura-Switch?label=Release&color=ff69b4" alt="Release">
</p>

在同一个原生 macOS 应用里完成 Nintendo Switch 的游戏与 Homebrew 安装、SD 卡管理、存档管理、Mod 管理与文件操作。

**macOS 15.0+**

[**🌸 下载 Sakura Switch v1.1.3 PRO**](https://github.com/borisovinfra/Sakura-Switch/releases/latest)

**PRO 代表的是功能，而不是价格。Sakura Switch PRO 是免费的，并且将一直免费。**

</div>

---

> **关于本文件**：这是 [README.md](README.md) 的简体中文翻译。界面、状态提示、错误信息与对话框均已支持简体中文（`zh-Hans` 语言包），语言随 macOS 系统设置自动切换。

---

## 🌸 关于本应用

**Sakura Switch** 是一款为方便操作 Nintendo Switch 而打造的原生 macOS 应用。

它把 **MTP、DBI Backend、SD 卡、Saves（存档）、Games & Mods（游戏与 Mod）、FTP 以及 Homebrew 目录** 整合到同一个界面中。

**v1.1.0 PRO** 大幅扩展了 Sakura Switch：现在可以直接在应用内查找并安装 Homebrew。

---

## 📦 Applications — Homebrew 目录

Sakura Switch PRO 内置了包含 **50 个 Nintendo Switch 应用与组件** 的目录。

不再需要手动到处找 release、下载压缩包、再研究内容该复制到哪里。

你只需要选择应用，**剩下的交给 Sakura。**

- 50 个 Homebrew 应用与组件
- 搜索
- 分类
- 获取最新版本
- 显示版本号与包大小
- 在遵守 GitHub API 配额的前提下安全更新目录
- 直接安装到已连接的 Nintendo Switch

![Applications — Homebrew 目录](Assets/screenshots/04-applications.png)

---

## ⚙️ 通用 Homebrew 安装器

PRO 版本包含通用的 Homebrew 安装系统。

支持的格式：

**NRO · OVL · ZIP · 7z · BIN**

Sakura 会自动识别包的类型以及所需的安装结构。

支持：

- 普通 Homebrew 应用；
- Tesla 叠加菜单（overlay）；
- 系统组件；
- 多组件压缩包；
- payload 文件；
- 带 SD 卡目录结构的包。

对于需要特殊安装路径的应用，Sakura 会自动使用对应的位置。

---

## 🛡️ 安全安装

Homebrew 安装器按事务（transaction）的方式实现。

在覆盖现有文件之前，Sakura 会先创建备份、安装新版本、校验结果，只有校验通过才提交本次操作。

**Backup → Install → Verify → Commit / Rollback**

一旦出错，Sakura 会尝试恢复到之前的状态。

更新时会保留用户自己的配置文件。

具体来说，已存在的：

`/switch/DBI/dbi.config`

**不会被替换。**

---

## 🎮 游戏安装

用 DBI 连接 Nintendo Switch，即可直接从 Mac 安装受支持的内容。

- 通过 DBI 使用 MTP
- DBI Backend
- NSP / NSZ / XCI / XCZ
- 安装到 SD 卡或 NAND
- 拖放（Drag & Drop）
- 显示速度与进度
- 实时操作日志

![安装](Assets/screenshots/01-install.png)

---

## 💾 SD 卡

完整地操作 Nintendo Switch SD 卡中的内容。

- 浏览文件与目录
- 在卡内目录结构中导航
- 处理 Atmosphère 文件
- 在 Mac 与 Switch 之间传输文件

![SD 卡](Assets/screenshots/02-sd-card.png)

---

## 💾 存档

操作已安装游戏的存档数据。

- 查找游戏
- 查看存档数据
- 管理 Nintendo Switch 存档

![存档](Assets/screenshots/03-saves.png)

---

## 🧩 游戏与 Mod

管理 Atmosphère 的修改内容。

- 查看 `atmosphere/contents`
- 识别已安装的修改
- 管理 Mod 的启停状态
- 处理游戏内容

![游戏与 Mod](Assets/screenshots/05-games-mods.png)

---

## 🔌 DBI Backend

直接在 Sakura Switch 中使用 DBI Backend。

- 启动与停止 DBI Backend
- 监控连接状态
- 查看地址与端口
- 实时事件日志

![DBI Backend](Assets/screenshots/06-dbi-backend.png)

---

## 🌐 FTP

通过局域网操作 Nintendo Switch。

- FTP 连接
- 无需 USB 即可传输文件
- 保存主机地址
- 通过 Wi-Fi 工作

![FTP](Assets/screenshots/07-ftp.png)

---

## 🌍 四种语言

Sakura Switch v1.1.3 支持：

**🇨🇳 简体中文**  
**🇷🇺 俄语**  
**🇬🇧 英语**  
**🇯🇵 日语**

语言会根据 macOS 的设置自动选择。

界面、状态、错误信息、对话框、提示以及 PRO 功能均已本地化。

---

## 🍎 原生 macOS 应用

Sakura Switch 是一个自带运行依赖的独立应用，MTP 所需的组件均已内置。

用户不需要手动安装：

**Homebrew · libmtp · libusb · MTP helper**

所需的库与 MTP helper 都在应用包内。

首次执行需要特权的 MTP 操作时，macOS 会弹出标准的管理员授权窗口，之后所需的运行环境会自动准备就绪。

---

## ⚙️ 系统要求

### Mac

- macOS 15.0 或更高版本

### Nintendo Switch

按所用功能不同，需要：

- DBI MTP Responder
- DBI Backend
- SD 卡访问
- FTP 连接

---

## 📦 安装 Sakura Switch

1. 打开 [**Releases**](https://github.com/borisovinfra/Sakura-Switch/releases/latest)。
2. 下载 `Sakura-Switch-v1.1.3-PRO.zip`。
3. 解压压缩包。
4. 把 `Sakura Switch.app` 移动到 `应用程序`（Applications）文件夹。
5. 启动应用。

### 从源码构建

```bash
brew install libmtp libusb   # 仅构建机需要
git clone https://github.com/borisovinfra/Sakura-Switch.git
cd Sakura-Switch
./scripts/build-app.sh --version=1.1.3      # 生成 build/Sakura Switch.app
./scripts/build-app.sh --version=1.1.3 --install   # 可选：安装到 /Applications
```

### 首次启动

Sakura Switch 目前发布时没有 Apple Developer 签名。

如果 macOS 阻止首次启动：

**系统设置 → 隐私与安全性 → 仍要打开**

允许一次之后，之后即可正常启动。

### 首次使用 MTP

首次使用 MTP 时，Sakura Switch 会自动安装辅助 MTP 组件和所需运行库。

macOS 会弹出一次标准的管理员授权窗口。

确认之后，后续的 MTP 操作无需再次输入密码。

**无需安装 Homebrew、libmtp、libusb，也无需手动安装 MTP helper。**

---

## 🔌 通过 MTP 连接

1. 在 Nintendo Switch 上启动 **DBI**。
2. 选择 **Run MTP Responder**。
3. 用 USB 线把 Switch 连接到 Mac。
4. 启动 Sakura Switch。
5. 检查连接状态。

连接成功后，应用会显示：

**Switch 已连接（MTP）**

---

## ❤️ Sakura Switch PRO 是免费的

名字里的 **PRO** 并不代表付费版本。

Sakura Switch PRO 免费提供。

我们不打算引入：

- 订阅；
- 付费解锁 PRO；
- 付费访问应用目录；
- 使用 Sakura Switch 的费用。

**PRO 代表的是功能，而不是价格。**

---

## 🌸 Sakura Switch v1.1.3 PRO

![Sakura Switch](Assets/screenshots/08-about.png)

**Project Sakura** 的当前稳定版本。

更新详情请见 [**Sakura Switch Release**](https://github.com/borisovinfra/Sakura-Switch/releases)。

---

<div align="center">

### 🌸 Project Sakura

为 Nintendo Switch 社区而做。

**Sakura Switch v1.1.3 PRO**

**樱花开满。🌸**

</div>

---

## ⚖️ 法律信息

**Sakura Switch** 是一个开源可获取的独立项目，用于管理 Nintendo Switch 上属于用户的文件与数据。

Sakura Switch 不包含也不分发游戏、固件、加密密钥或其他受版权保护的内容。

用户需自行确保其通过本应用传输、安装或使用的材料具有合法权利。

Nintendo Switch 是 Nintendo 的商标。

Sakura Switch 是独立项目，与 Nintendo 无关联，也未获得 Nintendo 的支持或认可。

---

## 📜 许可证

**Sakura Switch** 的源代码依据 **PolyForm Noncommercial License 1.0.0** 开放，允许研究、非商业使用、修改与分发。

**未经版权持有人事先书面许可，不得将 Sakura Switch 及其衍生作品用于商业用途。**

Copyright © 2026 Amir Borisov.

Sakura Switch 包含按各自许可证分发的第三方库，详情请见 `THIRD_PARTY_NOTICES.md` 与 `ThirdPartyLicenses/`。

另见 `LICENSE.md` 与 `NOTICE`。
