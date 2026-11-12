import '../../../../core/config/edition_config.dart';
import '../../domain/entities/user.dart';

/// 用户数据模型
/// 
/// 用于 JSON 序列化和反序列化
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.avatarUrl,
    required super.accountType,
    super.proExpiresAt,
    required super.limits,
    required super.usage,
    required super.createdAt,
    required super.updatedAt,
    super.isAdmin,
  });

  /// 从 JSON 创建
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final accountType = _parseAccountType(json['account_type'] as String?);
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      accountType: accountType,
      proExpiresAt: json['pro_expires_at'] != null
          ? DateTime.parse(json['pro_expires_at'] as String)
          : null,
      // Pro 版：额度按 Pro 版计算，不受服务端免费版配额限制
      limits: EditionConfig.isProEnabled
          ? AccountLimits.forAccountType(accountType)
          : AccountLimits(
              maxServers: json['max_servers'] as int? ?? 10,
              maxDevices: json['max_devices'] as int? ?? 2,
              storageQuotaMb: json['storage_quota_mb'] as int? ?? 100,
            ),
      usage: AccountUsage(
        serverCount: json['server_count'] as int? ?? 0,
        deviceCount: json['device_count'] as int? ?? 0,
        storageUsedMb: json['storage_used_mb'] as int? ?? 0,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  /// 从 Supabase Auth User 创建
  factory UserModel.fromSupabaseUser(
    dynamic supabaseUser,
    Map<String, dynamic>? metadata,
  ) {
    final accountType = _parseAccountType(
      metadata?['account_type'] as String?,
    );

    return UserModel(
      id: supabaseUser.id as String,
      email: supabaseUser.email as String,
      username: metadata?['username'] as String?,
      avatarUrl: metadata?['avatar_url'] as String?,
      accountType: accountType,
      proExpiresAt: metadata?['pro_expires_at'] != null
          ? DateTime.parse(metadata!['pro_expires_at'] as String)
          : null,
      limits: AccountLimits.forAccountType(accountType),
      usage: const AccountUsage.empty(),
      createdAt: DateTime.parse(supabaseUser.createdAt as String),
      updatedAt: DateTime.now(),
      isAdmin: false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar_url': avatarUrl,
      'account_type': accountType.name,
      'pro_expires_at': proExpiresAt?.toIso8601String(),
      'max_servers': limits.maxServers,
      'max_devices': limits.maxDevices,
      'storage_quota_mb': limits.storageQuotaMb,
      'server_count': usage.serverCount,
      'device_count': usage.deviceCount,
      'storage_used_mb': usage.storageUsedMb,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_admin': isAdmin,
    };
  }

  /// 转换为实体
  User toEntity() {
    return User(
      id: id,
      email: email,
      username: username,
      avatarUrl: avatarUrl,
      accountType: accountType,
      proExpiresAt: proExpiresAt,
      limits: limits,
      usage: usage,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isAdmin: isAdmin,
    );
  }

  /// 解析账号类型
  ///
  /// Pro 版发行包默认按 Pro 版处理：即使服务端标记为 `free`
  /// 或缺少该字段，也返回 [AccountType.pro]，确保 Pro 权益开箱可用。
  static AccountType _parseAccountType(String? type) {
    switch (type) {
      case 'lifetime':
        return AccountType.lifetime;
      case 'pro':
        return AccountType.pro;
      case 'free':
        return EditionConfig.isProEnabled
            ? AccountType.pro
            : AccountType.free;
      default:
        return EditionConfig.isProEnabled ? AccountType.pro : AccountType.free;
    }
  }
}
