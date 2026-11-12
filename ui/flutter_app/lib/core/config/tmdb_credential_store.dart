import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'env_config.dart';

/// 持久化用户手动填写的 TMDB 凭据（API Key 或 Read Access Token）。
///
/// 凭据只保存在本机 SharedPreferences 中，不会上传，也不会编译进安装包。
class TmdbCredentialStore {
  const TmdbCredentialStore._();

  static const String _prefsKey = 'tmdb_credential';

  /// 凭据变更计数器：已挂载的「发现」页监听它，变更后立即重新拉取数据。
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// 启动时调用：把本机保存的凭据载入 [EnvConfig]。
  static Future<void> loadAndApply() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      EnvConfig.applyTmdbCredential(prefs.getString(_prefsKey) ?? '');
    } catch (_) {
      // 读取失败时保持 .env 中的配置
    }
  }

  static Future<String> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefsKey) ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<void> save(String credential) async {
    final value = credential.trim();
    final prefs = await SharedPreferences.getInstance();
    if (value.isEmpty) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, value);
    }
    EnvConfig.applyTmdbCredential(value);
    revision.value++;
  }

  static Future<void> clear() => save('');
}
