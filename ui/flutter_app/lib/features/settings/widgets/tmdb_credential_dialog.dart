import 'package:flutter/material.dart';

import '../../../core/config/tmdb_credential_store.dart';

/// 打开「TMDB 凭据」输入弹窗。保存成功后返回 true。
Future<bool> showTmdbCredentialDialog(BuildContext context) async {
  final current = await TmdbCredentialStore.read();
  if (!context.mounted) return false;
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => TmdbCredentialDialog(initialValue: current),
  );
  return saved ?? false;
}

class TmdbCredentialDialog extends StatefulWidget {
  const TmdbCredentialDialog({super.key, this.initialValue = ''});

  final String initialValue;

  @override
  State<TmdbCredentialDialog> createState() => _TmdbCredentialDialogState();
}

class _TmdbCredentialDialogState extends State<TmdbCredentialDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  bool _saving = false;

  bool get _isZh =>
      Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await TmdbCredentialStore.save(_controller.text);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    await TmdbCredentialStore.clear();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isZh = _isZh;

    return AlertDialog(
      title: Text(isZh ? 'TMDB 数据源' : 'TMDB Data Source'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isZh
                  ? '粘贴 TMDB 的「API Key (v3 auth)」或「API Read Access Token (v4 auth)」，保存后立即生效，「发现」页即可加载海报与推荐。'
                  : 'Paste your TMDB "API Key (v3 auth)" or "API Read Access Token (v4 auth)". It takes effect immediately and enables posters and picks on Discover.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                labelText: 'API Key / Read Access Token',
                hintText: 'eyJhbGciOi... 或 0123456789abcdef...',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 10),
            Text(
              isZh
                  ? '获取方式：themoviedb.org → 设置 → API → 复制密钥'
                  : 'Get it at themoviedb.org → Settings → API',
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : _clear,
          child: Text(isZh ? '清除' : 'Clear'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(isZh ? '取消' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(isZh ? '保存' : 'Save'),
        ),
      ],
    );
  }
}
