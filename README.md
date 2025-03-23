# Trackord

<img src="./assets/icon/icon.png" style="border-radius: 10px;" width="50" height="50" />

这是极简风格自定义记录软件Trackord的源码，也可前往[App Store](https://apps.apple.com/us/app/trackord/id6743145159)安装

### 环境配置:

1. 此系Flutter项目，需安装Flutter SDK，请根据[Flutter官网](https://docs.flutter.dev/get-started/install/windows/mobile)和系统配置好相关环境。
2. Clone或者下载本repo，并用VSCode打开文件夹。
3. 在VSCode Terminal运行```flutter pub get```获取相关依赖。
4. 在VSCode Terminal运行```flutter gen-l10n```生成本地化文件。
5. *[可选] 在VSCode Terminal运行```dart run flutter_native_splash:create```生成启动画面*
6. *[可选] 在VSCode Terminal运行```dart run flutter_launcher_icons:generate```生成app图标*
5. 安装相应模拟器（安卓或者iOS）并运行。

### 保存.arb文件时自动生成 l10n 文件
- 安装 [pucelle.run-on-save](https://marketplace.cursorapi.com/items?itemName=pucelle.run-on-save)
- 复制以下配置到 *VSCode* 的 *settings.json*
    ```json
    "runOnSave.commands": [
            {
                "match": ".arb",
                "command": "flutter gen-l10n",
                "runIn": "terminal",
            },
        ],
    "runOnSave.defaultRunIn": "terminal",
    "runOnSave.onlyRunOnManualSave": true,
    ```
