# LifeBook

个人的“起居注”：用图标快速记录每天发生的事，并在日历、事件流和趋势中回顾生活。

## 1.0 功能

- 原生 SwiftUI + SwiftData，iOS 17+
- 月历首页：每天最多展示 3 个事件图标
- 事件流：按天回顾所有记录
- 快捷记录：发生一次、数值、时长、评分和文字日记
- 内置记录明细：游泳、理发、生病、大餐、体重、睡眠、心情和日记都有专属字段
- 健康记录：可填写疾病名称、症状、体温、严重程度、用药与就医情况
- 自定义事件：名称、类型、单位、图标和颜色
- 基础分析：本周记录、连续天数、近 30 天事件频率
- 数据导出：JSON 完整备份和 CSV 表格分析，包含结构化记录明细
- AI 助理：用户配置自己的 OpenAI API Key，询问最近 30 天的记录
- 隐私保护：API Key 存储在 Keychain；每次向 AI 发送记录前都要明确确认

基础记录完全离线可用。ChatGPT Plus/Pro 订阅不能抵扣 OpenAI API 用量，AI 功能由用户自己的 API Key 单独计费。

## 本地运行

1. 安装 Xcode 16 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen)。
2. 在仓库根目录运行：

   ```bash
   xcodegen generate
   open LifeBook.xcodeproj
   ```

3. 在 Xcode 中选择一个 iOS 17+ 模拟器并运行。
4. 如需使用 AI，在“设置 → OpenAI”中填写 API Key 和模型名称。

默认模型为 `gpt-5.6-sol`，可以在设置中改成 API 账户有权使用的其他 Responses API 模型。

## 自动化测试

GitHub Actions 使用 macOS 15、Xcode 16.4 和 iPhone 16 模拟器执行：

- 日历与时间计算单元测试
- 连续记录和事件频率单元测试
- SwiftData 内存数据库集成测试
- JSON / CSV 导出测试
- Keychain 保存、读取和删除测试
- OpenAI Responses API 请求与错误处理测试（网络层 Mock，不消耗 API）
- 主导航、快捷记录、自定义事件和 AI 入口 UI 测试

测试结果、构建日志和覆盖率数据会作为 `ios-test-results` artifact 保存 14 天。

## 签名并导出 IPA

`.github/workflows/package-ipa.yml` 支持手动生成 `ad-hoc`、`development` 或
`app-store-connect` IPA。仓库需要配置以下 Actions Secrets：

- `APPLE_CERTIFICATE_BASE64`：导出为 `.p12` 的签名证书，再做 Base64 编码
- `APPLE_CERTIFICATE_PASSWORD`：`.p12` 密码
- `APPLE_PROVISIONING_PROFILE_BASE64`：`.mobileprovision` 文件的 Base64
- `APPLE_KEYCHAIN_PASSWORD`：CI 临时 Keychain 密码，可使用随机强密码
- `APPLE_TEAM_ID`：Apple Developer Team ID
- `APPLE_BUNDLE_ID`：Provisioning Profile 覆盖的 Bundle ID

运行 `Package IPA` 工作流后，CI 会校验证书与 Profile 的 Team/Bundle ID、
归档、导出 IPA、验证代码签名，并上传 IPA 和 SHA-256 文件。直接安装到已登记设备，
请选择 `ad-hoc`，并确保设备 UDID 已包含在 Provisioning Profile 中。
工作流会将这些便于选择的名称映射为 Xcode 16 的 `release-testing`、`debugging`
和 `app-store-connect` 导出方法。

## AI 数据边界

- 默认不向 OpenAI 发送任何日记数据。
- 当前版本只发送最近 30 天的结构化文字摘要。
- 每次请求都必须单独勾选同意。
- AI 回答被提示引用日期、不把相关性当因果、不进行医疗诊断。
- API Key 使用 `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`，不会通过 iCloud Keychain 同步。

## 当前外部依赖

- 真机 IPA 必须使用 Apple Developer 签名材料；未签名 IPA 不能安装到普通 iPhone。
- iCloud 数据同步还需要在 Apple Developer 中创建 CloudKit Container，并让 App ID
  和 Provisioning Profile 包含对应 entitlement。仓库不会伪造或提交这些账户级配置。
