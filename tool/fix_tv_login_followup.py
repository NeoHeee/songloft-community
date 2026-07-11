from pathlib import Path

path = Path(__file__).resolve().parents[1] / "lib/features/auth/presentation/login_page.dart"
text = path.read_text(encoding="utf-8")

old = '''      onFieldSubmitted: (_) {
        if (isLast) {
          _handleLogin();
        } else {
          _apiUrlFocusNode.requestFocus();
        }
      },
'''
new = '''      onFieldSubmitted: (_) {
        if (isLast) {
          _handleLogin();
        } else {
          nextFocusNode.requestFocus();
        }
      },
'''
if old not in text:
    raise RuntimeError("missing password next-focus anchor")
text = text.replace(old, new, 1)

old_load = '''      if (servers.length == 1 && servers.first.url.isNotEmpty) {
        _apiUrlController.text = servers.first.url;
      }
'''
new_load = '''      if (servers.length == 1 && servers.first.url.isNotEmpty) {
        _apiUrlController.text = servers.first.url;
      } else if (servers.length >= 2) {
        final currentUrl = ref.read(baseUrlProvider);
        if (!servers.any((entry) => entry.url == currentUrl)) {
          ref.read(baseUrlProvider.notifier).set(servers.first.url);
        }
      }
'''
if old_load not in text:
    raise RuntimeError("missing saved-server fallback anchor")
text = text.replace(old_load, new_load, 1)

path.write_text(text, encoding="utf-8")
print("TV login follow-up fixes applied")
