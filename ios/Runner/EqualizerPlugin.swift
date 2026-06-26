import Flutter

/// iOS 上 just_audio 走 media_kit/mpv，EQ 通过 mpv 音频滤镜实现（见 SongloftJustAudioPlatform）。
/// 此插件仅注册 MethodChannel 以避免 MissingPluginException，所有操作均为 no-op。
class EqualizerPlugin: NSObject {
    static let shared = EqualizerPlugin()

    private var channel: FlutterMethodChannel?

    private override init() {
        super.init()
    }

    func register(with messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "com.songloft.equalizer", binaryMessenger: messenger)
        channel?.setMethodCallHandler { call, result in
            switch call.method {
            case "initialize":
                result(false)
            case "apply", "setEnabled", "setBandGain":
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
