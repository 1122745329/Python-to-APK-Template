# TouchMapper v1.1 — 安卓键位映射工具（类 K2er）

把**外接键盘 / 游戏手柄**的按键，映射到**屏幕任意坐标**，无需 Root、可上架、配置跨设备通用。

---

## ✨ v1.1 新增（本次重点）

### ⚡ Shizuku 低延迟路径

| 维度 | 无障碍（兜底） | Shizuku（优先） |
|---|---|---|
| 单次注入延迟 | 50–80 ms | **5–15 ms** |
| 持续按压（瞄准） | 抖动、丢帧 | ✅ 稳定 60fps |
| 游戏识别 | 可能判为"模拟点击" | ✅ 与真触摸一致 |
| 需要 Root | 否 | **否**（adb 授权一次） |
| 可上架 | ✅ | ✅ |
| 断线行为 | — | 🔄 **自动降级到无障碍** |

**原理**：借 `adb shell` 的 shell 权限（uid=2000），通过 Binder 反射调用
`InputManager.injectInputEvent()`——与 `adb shell input tap` 同源，但常驻进程、无 fork 开销。

### 📐 坐标按比例归一化（配置跨设备通用）

```json
// v1（已废弃）：像素绝对值，换手机即错位
{ "x": 900, "y": 1700 }

// v2（当前）：比例 + 参考分辨率
{ "x": 0.833, "y": 0.708, "refW": 1080, "refH": 2400 }
```

**关键**：按 **density 折算后的逻辑分辨率**归一化（非 raw px），
还原时用 `scale = min(w/refW, h/refH)` + 居中偏移，对应"游戏安全区居中"的真实场景。

旧配置**自动迁移**，无需重摆。

---

## 📐 架构（v1.1）

```
输入 → onKeyEvent() → 查 keymap.json(v2 归一化)
                            │
                    ┌───────┴────────┐
                    ▼                ▼
           Shizuku（优先）     无障碍（兜底）
           ~5-15ms             ~50-80ms
           与真触摸一致         兼容所有系统
                    │                │
                    └───────┬────────┘
                            ▼
                      InputDispatcher → 游戏
```

完整图见 [docs/architecture_v2.mmd](docs/architecture_v2.mmd)

---

## 🚀 快速开始

### 1. 编译

```bash
cd TouchMapper
./gradlew :app:assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

### 2. 授权（3 步，缺一不可）

| 权限 | 路径 | 说明 |
|---|---|---|
| 悬浮窗 | `设置 → 应用 → TouchMapper → 悬浮窗` | 显示准星 |
| 无障碍 | `设置 → 无障碍 → TouchMapper 键位映射` | 拦截按键 + 兜底注入 |
| **Shizuku（可选但强烈推荐）** | 见下 | 低延迟注入 |

### 3. 启用 Shizuku（一次即可）

```bash
# 电脑执行（Android 11+ 可用无线调试，免数据线）
adb shell sh /sdcard/Android/data/rikka.shizuku/files/start.sh
```

然后在 Shizuku 应用中点击「启动」→ 授权 TouchMapper。
App 内路径：`首页 → ⚡ Shizuku 低延迟设置 → 检测连接`

### 4. 摆点

1. 打开「映射编辑器」→ 点 `+` 添加准星
2. 拖动准星到游戏按钮正上方（坐标实时显示为比例值）
3. 长按准星 → 绑定按键 + 选动作类型
4. 保存 → 返回游戏 → 按键盘/手柄对应键

---

## 🎮 动作类型

| 类型 | 场景 | Shizuku 优势 |
|---|---|---|
| `tap` | 跳跃、技能、确认 | 可控制 DOWN/UP 间隔 |
| `long_press` | 瞄准、蓄力 | **60fps 持续注入，不抖动** |
| `swipe` | 摇杆移动、镜头 | 插值平滑 |
| `toggle` | 换弹、切枪 | — |
| `macro` | 连招 | — |
| `key_passthrough` | 直接透传 keyCode | **游戏识别为真实按键** |

---

## 📄 配置格式 v2

```json
{
  "version": 2,
  "enabled": true,
  "toggle_hotkey": "volume_up",
  "remaps": {
    "w": {
      "type": "swipe",
      "x": 0.500, "y": 0.750,
      "toX": 0.500, "toY": 0.500,
      "anchor": "center",
      "refW": 1080, "refH": 2400
    },
    "l": {
      "type": "long_press",
      "x": 0.944, "y": 0.542,
      "interval": 16,
      "refW": 1080, "refH": 2400
    },
    "space": { "type": "tap", "x": 0.833, "y": 0.708, "refW": 1080, "refH": 2400 }
  },
  "active_profile": "com.tencent.tmgp.sgame"
}
```

---

## 📁 项目结构

```
TouchMapper/
├── app/                          # 主 App（普通权限）
│   ├── build.gradle.kts          # ← 新增 Shizuku 依赖
│   └── src/main/
│       ├── AndroidManifest.xml   # ← 注册 ShizukuSettings/Guide
│       ├── assets/default_keymap.json  # ← v2 归一化
│       ├── java/com/touchmapper/
│       │   ├── KeymapService.kt         # ← 双路径 + 归一化
│       │   ├── OverlayEditorActivity.kt # ← 保存比例坐标
│       │   ├── CoordinateNormalizer.kt  # ★ 新增：坐标归一化
│       │   ├── shizuku/ShizukuBridge.kt # ★ 新增：Shizuku 客户端
│       │   ├── ShizukuSettingsActivity.kt# ★ 新增：设置页 + 延迟基准测试
│       │   ├── ShizukuGuideActivity.kt  # ★ 新增：授权引导
│       │   ├── GuideAdapter.kt          # ★ 新增
│       │   ├── ProfileManager.kt
│       │   ├── MainActivity.kt
│       │   ├── KeymapForegroundService.kt
│       │   └── ...
│       └── res/
│           ├── layout/
│           │   ├── activity_main.xml          # ← + Shizuku 入口
│           │   ├── activity_editor.xml         # ← + 路径状态条
│           │   ├── activity_shizuku_settings.xml # ★ 新增
│           │   └── activity_shizuku_guide.xml  # ★ 新增
│           └── drawable/ic_bolt.xml            # ★ 新增
├── shizuku-server/               # ★ 新增：shell 权限服务端
│   ├── build.gradle.kts
│   ├── AndroidManifest.xml
│   ├── README.md
│   └── src/main/
│       ├── aidl/.../IInputInjector.aidl
│       └── java/.../ServerService.kt  # 反射 InputManager
├── docs/
│   ├── architecture.mmd
│   ├── architecture_v2.mmd       # ★ 新增
│   └── adr-001-dual-path.md       # ★ 新增：架构决策记录
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── pack_apk.sh
└── README.md
```

---

## ⚠️ 已知限制

1. **反作弊手游**：《和平精英》《王者荣耀》等会屏蔽 shell 来源的输入事件。
   这是 Android 所有**非内核**映射工具的共同天花板（K2er 同理）。
   **Root + uinput 内核路径**可实现完全绕过，但无法上架。
2. **Shizuku 需重启后重连**：Android 重启会杀掉 shell 进程。
   Android 11+ 可用"无线调试"自动重连，无需数据线。
3. **Android 14 前台服务**：`specialUse` 类型需在 Manifest 说明用途（已处理）。
4. **手柄修饰键**：`ctrl+shift` 组合依赖 `event.isCtrlPressed`，
   部分廉价 OTG 转接器不报修饰键状态，建议用 Shizuku 的 `key_passthrough`。

---

## 🗺️ 后续计划

- [ ] 无线调试自动启动 Shizuku（免 adb 重连）
- [ ] 编辑器叠加"安全区参考框"可视化
- [ ] 社区配置市场（比例坐标天然可分享）
- [ ] 宏录制（边操作边记录）
- [ ] 摇杆死区 + 灵敏度曲线
- [ ] Shizuku 断线指数退避重连
- [ ] 可选 Root/uinput 内核路径（面向 rooted 用户，性能极致）

---

## 📄 License

MIT — 自由使用、修改、分发。
