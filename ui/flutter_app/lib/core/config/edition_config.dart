/// 应用发行版本（Edition）配置。
///
/// BovaPlayer 默认以 **Pro 版** 发行：安装后即拥有 Pro 版全部权益，
/// 不再依赖服务端账号等级或订阅状态。
///
/// 如需回退到「社区免费版 + 订阅解锁」的发行方式，
/// 把 [isProEdition] 改成 `false` 后重新构建即可。
class EditionConfig {
  const EditionConfig._();

  /// 是否按 Pro 版发行。默认 `true`。
  static const bool isProEdition = true;

  /// Pro 版下账号类型的兜底值（与服务端 `account_type` 字段保持一致）。
  static const String proAccountType = 'pro';

  /// Pro 版是否放行 Pro 权益。
  ///
  /// 与登录状态无关：未登录时同样按 Pro 版处理。
  static bool get isProEnabled => isProEdition;
}
