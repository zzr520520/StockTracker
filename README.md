# StockTracker - iOS 涨跌网格看板应用

基于 SwiftUI 的股票涨跌网格记录与自选股票管理应用，通过 GitHub Actions 自动构建生成 IPA。

## 工程结构

```
StockTracker/
├── .github/workflows/
│   └── build-ipa.yml          # GitHub Actions 自动构建配置
├── StockTracker/
│   ├── StockTrackerApp.swift   # App 入口
│   ├── Models.swift            # 数据模型与持久化存储
│   ├── THSWebView.swift        # 同花顺 WebKit 容器
│   ├── FloatingTHSButton.swift # 全局悬浮按钮
│   ├── DashboardView.swift     # 首页行情看板
│   ├── EditRecordView.swift    # 数据录入页
│   ├── HistoryView.swift       # 历史记录页
│   ├── StockFavoritesView.swift # 自选股票页
│   ├── MainTabView.swift       # 底部 Tab 导航
│   └── Assets.xcassets/        # 应用资源
├── project.yml                 # XcodeGen 工程配置
├── .gitignore
└── README.md
```

## 技术栈

- SwiftUI + WebKit
- UserDefaults 本地 JSON 离线存储
- 零第三方依赖
- iOS 16.0+ 部署目标
- XcodeGen 自动生成 .xcodeproj

## 功能模块

1. **首页看板** - 日期选择 + 8行5列涨跌网格 + 分值统计
2. **数据录入** - 点击网格切换涨/跌，输入分值，保存记录
3. **历史记录** - 按日期筛选，缩略图预览，滑动删除
4. **自选股票** - 添加/删除/置顶股票，一键跳转同花顺行情

## GitHub Actions 自动构建

推送到 `main` 或 `master` 分支后，GitHub Actions 会自动：

1. 安装 XcodeGen
2. 从 `project.yml` 生成 `StockTracker.xcodeproj`
3. 使用 `xcodebuild archive` 构建未签名的 Archive
4. 打包为 IPA 并上传为 Artifact

### 获取 IPA 文件

1. 进入 GitHub 仓库 → **Actions** 标签页
2. 点击最新的 "Build iOS IPA" 运行记录
3. 在页面底部 **Artifacts** 区域下载 `StockTracker-IPA`
4. 解压后得到 `StockTracker.ipa`

## 本地构建 (需要 Mac + Xcode)

```bash
# 1. 安装 XcodeGen
brew install xcodegen

# 2. 生成 Xcode 工程
xcodegen generate

# 3. 构建 Archive (无需签名)
xcodebuild archive \
  -project StockTracker.xcodeproj \
  -scheme StockTracker \
  -configuration Release \
  -sdk iphoneos \
  -archivePath ./build/StockTracker.xcarchive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  DEVELOPMENT_TEAM=""

# 4. 打包 IPA
mkdir -p ./build/Payload
cp -r ./build/StockTracker.xcarchive/Products/Applications/StockTracker.app ./build/Payload/
cd ./build
zip -r StockTracker.ipa Payload
```

## 安全提示

**切勿在代码、聊天或任何公开场合分享 GitHub Personal Access Token。** 如果令牌已泄露，请立即前往 GitHub Settings → Developer settings → Personal access tokens 撤销。
