import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/edition_config.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/widgets/bova_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/account/account_admin_card.dart';
import '../widgets/account/account_hero_card.dart';
import '../widgets/account/account_logout_card.dart';
import '../widgets/account/account_plan_card.dart';
import '../widgets/account/account_sync_card.dart';
import '../widgets/account/account_theme.dart';
import '../widgets/account/account_upgrade_card.dart';
import '../widgets/account/account_usage_card.dart';

/// Account center page.
///
/// Set [embedded] = true when shown inside the desktop workspace shell
/// (no Scaffold / AppBar of its own).
class AccountPage extends StatefulWidget {
  const AccountPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignSystem.durationSlow,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignSystem.easeOutQuint,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignSystem.easeOutQuint,
      ),
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AccountColors.of(context);
    final isMobile = DesignSystem.isMobile(context);

    final body = Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.profile;
        final scrollContent = FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: DesignSystem.isDesktop(context) ? 920 : 760,
                ),
                child: _AccountBody(
                  user: user,
                  authProvider: authProvider,
                  localMode: authProvider.isLocalMode,
                ),
              ),
            ),
          ),
        );

        final content = SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? DesignSystem.space4 : DesignSystem.space6,
            DesignSystem.space4,
            isMobile ? DesignSystem.space4 : DesignSystem.space6,
            DesignSystem.space8,
          ),
          child: scrollContent,
        );

        if (widget.embedded) {
          return ColoredBox(color: c.canvas, child: content);
        }

        return SafeArea(top: true, child: content);
      },
    );

    if (widget.embedded) return body;

    final l = S.of(context);
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: c.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l.accountCenter,
          style: TextStyle(
            fontSize: DesignSystem.textLg,
            fontWeight: DesignSystem.weightSemibold,
            color: c.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: body,
    );
  }
}

// ─── Body: the column of cards ──────────────────────────────────────

class _AccountBody extends StatelessWidget {
  final User user;
  final AuthProvider authProvider;
  final bool localMode;

  const _AccountBody({
    required this.user,
    required this.authProvider,
    required this.localMode,
  });

  @override
  Widget build(BuildContext context) {
    final isWide =
        DesignSystem.isDesktop(context) || DesignSystem.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero
        const AccountHeroCard(),
        const SizedBox(height: DesignSystem.space4),

        // Plan + Usage side-by-side on desktop
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AccountPlanCard(user: user)),
              const SizedBox(width: DesignSystem.space4),
              Expanded(child: AccountUsageCard(user: user)),
            ],
          )
        else ...[
          AccountPlanCard(user: user),
          const SizedBox(height: DesignSystem.space4),
          AccountUsageCard(user: user),
        ],

        const SizedBox(height: DesignSystem.space4),

        // Cloud Sync（本地模式无需云同步）
        if (!localMode) const AccountSyncCard(),

        // Admin (only if admin)
        if (user.isAdmin) ...[
          const SizedBox(height: DesignSystem.space4),
          const AccountAdminCard(),
        ],

        // Upgrade CTA（Pro 发行版无需展示升级入口）
        if (!localMode && !user.isLifetime && !EditionConfig.isProEnabled) ...[
          const SizedBox(height: DesignSystem.space4),
          AccountUpgradeCard(user: user),
        ],

        // Logout（本地模式没有登录态）
        if (!localMode) ...[
          const SizedBox(height: DesignSystem.space4),
          AccountLogoutCard(authProvider: authProvider),
        ],
      ],
    );
  }
}
