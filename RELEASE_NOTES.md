# Gridnote v1.0.1

Gridnote v1.0.1 is a data-safety update for the stable personal-Mac release.

## 本次修复

- 将 SwiftData 数据库从系统共享的 `Application Support/default.store` 移至 Gridnote 专属目录。
- 首次升级时通过只读 SQLite 快照自动迁移仍可读取的 v1.0.0 书库。
- 迁移完成前校验 Gridnote 模型表和数据库完整性；迁移失败时停止初始化，不创建空书库掩盖错误。
- 单元测试宿主强制使用内存数据库，不再接触用户的真实书库。

建议所有 v1.0.0 用户升级。此修复不会删除原始 TXT 或 EPUB 文件。

## 功能预览

### 办公伪装：小说在顶部公式栏

启动后默认显示电子表格式工作区。小说位于工具栏下方、`fx` 标记右侧的长编辑栏，不会写入表格单元格；按 `F7`、`F8` 可直接翻页。

![Gridnote office workspace](https://raw.githubusercontent.com/ZOB2077/Gridnote/main/docs/images/office-workspace.jpg)

### 普通悬浮阅读

悬浮窗显示正文、书名与精确进度，并提供搜索、书签、章节和排版入口。它与办公公式栏使用同一阅读位置。

![Gridnote floating reader](https://raw.githubusercontent.com/ZOB2077/Gridnote/main/docs/images/floating-reader.png)

### 超级隐蔽模式

超级隐蔽模式移除背景、边框和控制组件，只保留正文。下图中的灰色小说文本是覆盖在日常窗口上的无边框阅读层。

![Gridnote Super Stealth mode](https://raw.githubusercontent.com/ZOB2077/Gridnote/main/docs/images/super-stealth.png)

## 核心体验

- 原创电子表格式办公工作区，使用全合成手机租赁演示数据。
- 小说正文显示在顶部公式栏，不进入表格单元格。
- 普通悬浮阅读与无背景、无边框的超级隐蔽模式。
- `F7` 上一页、`F8` 下一页、`F9` 全局显示或隐藏。
- 办公公式栏与悬浮窗双向同步阅读位置。
- 全文搜索、书签、章节、精确进度和排版设置。
- TXT 与无 DRM EPUB 本地导入；TXT 支持 UTF-8、UTF-16、GB18030。
- 无账号、无网络、无遥测、无广告、无云同步。

## 安装

1. Apple Silicon Mac 下载 `Gridnote-macOS.dmg` 或 `Gridnote-macOS.zip`。
2. 将 `Gridnote.app` 移入“应用程序”。
3. 首次启动若被阻止，请在 Finder 中右键选择“打开”，或在“系统设置 → 隐私与安全性”中确认。

本版本采用 ad-hoc 签名，未经过 Apple 公证。发布附件包含 SHA-256 校验文件。

## 隐私与数据

公开前审计覆盖完整 Git 历史、当前源码、测试夹具和发布附件。未发现密钥、个人路径、联系方式、客户记录、真实订单行或原始业务文件。演示工作簿中的标识、日期、金额、状态和物流字段均为合成值。

## 功能边界

不包含 PDF、DRM 处理、完整 Excel 兼容、XLSX 导入导出、公式、宏、OCR、联网书城、账号、云同步、遥测、Apple 公证或任意组合键录制。

## 许可

源码依据 Gridnote Source-Available Non-Commercial License v1.0 公开。个人、教育、研究和其他非商业用途按许可开放；商业分发、付费服务、OEM、白标和其他获利用途需要单独书面授权。

## 支持开发

如果 Gridnote 对你有帮助，可以通过微信支付自愿请作者喝杯咖啡。

<p align="center">
  <img src="https://raw.githubusercontent.com/ZOB2077/Gridnote/main/docs/images/wechat-donation.jpg" width="300" alt="Gridnote 微信赞助码">
</p>

捐赠不构成商业授权、付费服务、功能承诺或优先支持。
