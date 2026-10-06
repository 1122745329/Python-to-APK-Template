# Changelog

## [1.1.0] - 2026-10-06

### Added
- **Shizuku 低延迟注入路径**
  - `ShizukuBridge`：AIDL Binder 客户端，自动降级到无障碍
  - `shizuku-server`：shell 权限服务端，反射调用 `InputManager.injectInputEvent`
  - 延迟从 50-80ms 降至 5-15ms
  - 支持 `key_passthrough`：直接透传 keyCode，游戏识别为真实按键
- **坐标按比例归一化（v2 配置格式）**
  - 按 density 折算的逻辑分辨率归一化（非 raw px）
  - 还原用 `scale = min(w/refW, h/refH)` + 居中偏移，避免越界
  - v1 → v2 自动迁移，旧配置无需重摆
- **延迟基准测试**：`ShizukuSettingsActivity` 可跑 100 次注入统计平均耗时
- **架构决策记录** `docs/adr-001-dual-path.md`

### Changed
- `KeymapService` 重构为双路径路由器
- `OverlayEditorActivity` 保存比例坐标，底部新增"当前注入路径"状态条
- `default_keymap.json` 升级为 v2 格式
- 版本号 → 1.1.0，minSdk 24

### Security
- Shizuku Server 不监听网络、不上传数据、仅暴露 5 个注入动作
- 符合 Shizuku 官方安全模型

## [1.0.0] - 2026-09-15

### Added
- 无障碍服务拦截按键（`onKeyEvent` + `canRequestFilterKeyEvents`）
- 悬浮映射编辑器（准星可拖动、长按改键）
- 5 种动作：tap / long_press / swipe / toggle / macro
- 按前台包名自动切换配置集（Profile）
- 配置导入/导出、新手引导、前台保活
- Material 3 + 深色主题
