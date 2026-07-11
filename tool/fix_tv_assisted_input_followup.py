from pathlib import Path

root = Path(__file__).resolve().parents[1]
service_path = root / "lib/features/auth/presentation/tv_assisted_input_service.dart"
dialog_path = root / "lib/features/auth/presentation/tv_assisted_input_dialog.dart"

service = service_path.read_text(encoding="utf-8")
service = service.replace(
    "throw SocketException('未找到可用的局域网 IPv4 地址');",
    "throw const SocketException('未找到可用的局域网 IPv4 地址');",
    1,
)
service_path.write_text(service, encoding="utf-8")

dialog = dialog_path.read_text(encoding="utf-8")
old = "import 'tv_assisted_input_service.dart';\n"
new = (
    "import 'tv_assisted_input_service_stub.dart'\n"
    "    if (dart.library.io) 'tv_assisted_input_service.dart';\n"
)
if old not in dialog and new not in dialog:
    raise RuntimeError("missing assisted input service import")
dialog = dialog.replace(old, new, 1)
dialog_path.write_text(dialog, encoding="utf-8")

print("TV assisted-input follow-up fixes applied")
