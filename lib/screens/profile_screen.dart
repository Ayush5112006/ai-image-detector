import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/skeleton.dart';

Future<void> _confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: const Row(
        children: [
          Icon(Icons.logout, color: AppColors.danger, size: 24),
          SizedBox(width: 10),
          Text('Sign Out'),
        ],
      ),
      content: const Text(
        'Are you sure you want to sign out?',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await ApiService.clearSession();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  String _totalScans = '0';
  String _fakesFound = '0';
  String _cleared = '0';
  int _level = 1;
  int _xpIntoLevel = 0;
  int _xpForNext = 100;
  bool _premiumActive = false;
  bool _premiumToggling = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await Future.wait([_loadFromPrefs(), _loadFromBackend()]);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final name = prefs.getString('profile_name');
    final email = prefs.getString('profile_email');
    if ((name != null && name.isNotEmpty) ||
        (email != null && email.isNotEmpty)) {
      setState(() {
        _name = name ?? _name;
        _email = email ?? _email;
      });
    }
  }

  Future<void> _loadFromBackend() async {
    try {
      final results = await Future.wait([
        ApiService.me(),
        ApiService.stats(),
        ApiService.premiumStatus(),
      ]);
      if (!mounted) return;
      final user = results[0];
      final stats = results[1];
      final premium = results[2];
      setState(() {
        _name = user['name']?.toString() ?? _name;
        _email = user['email']?.toString() ?? _email;
        _totalScans = (stats['totalScans'] ?? 0).toString();
        _fakesFound = (stats['fakesFound'] ?? 0).toString();
        _cleared = (stats['cleared'] ?? 0).toString();
        _level = (stats['level'] ?? 1) as int;
        _xpIntoLevel = (stats['xpIntoLevel'] ?? 0) as int;
        _xpForNext = (stats['xpForNext'] ?? 100) as int;
        _premiumActive = premium['active'] == true;
      });
    } catch (e) {
      debugPrint('Profile backend load failed: $e');
    }
  }

  Future<void> _togglePremium() async {
    setState(() => _premiumToggling = true);
    try {
      if (_premiumActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Subscription is active and can only be canceled via the web dashboard.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final premium = await ApiService.activatePremium();
        if (!mounted) return;
        setState(() => _premiumActive = premium['active'] == true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Premium! Enjoy unlimited scans.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _premiumToggling = false);
    }
  }

  Widget _buildSkeletonContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 30,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              AppSkeleton.circle(size: 88),
              const SizedBox(height: 12),
              AppSkeleton.box(width: 150, height: 18),
              const SizedBox(height: 8),
              AppSkeleton.box(width: 210, height: 10),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _skeletonStatColumn(),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              _skeletonStatColumn(),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              _skeletonStatColumn(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppSkeleton.box(width: 130),
                  AppSkeleton.box(width: 90, height: 10),
                ],
              ),
              const SizedBox(height: 12),
              AppSkeleton.box(height: 8, radius: 10),
              const SizedBox(height: 12),
              AppSkeleton.box(width: 230, height: 10),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              AppSkeleton.box(
                width: 42,
                height: 42,
                radius: AppRadius.sm,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.box(width: 110),
                    const SizedBox(height: 8),
                    AppSkeleton.box(width: 170, height: 10),
                  ],
                ),
              ),
              AppSkeleton.box(width: 64, height: 30, radius: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skeletonStatColumn() {
    return Column(
      children: [
        AppSkeleton.box(width: 40, height: 20),
        const SizedBox(height: 6),
        AppSkeleton.box(width: 56, height: 9),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loading) ...[
                _buildSkeletonContent(),
              ] else ...[
                // Profile header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ProfileAvatar(
                      size: 88,
                      name: _name,
                      onTap: () =>
                          Navigator.pushNamed(context, '/profile_details'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats card
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ProfileStatItem(
                      num: _totalScans,
                      name: 'Total Scans',
                      color: AppColors.primary,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider,
                    ),
                    _ProfileStatItem(
                      num: _fakesFound,
                      name: 'Fakes Found',
                      color: AppColors.danger,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.divider,
                    ),
                    _ProfileStatItem(
                      num: _cleared,
                      name: 'Cleared',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Level card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level $_level Analyst',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '$_xpIntoLevel% to next',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value:
                            (_xpIntoLevel / (_xpForNext == 0 ? 100 : _xpForNext))
                                .clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFEFF1F5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Run scans to earn XP and unlock higher levels',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Premium card
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _premiumActive
                            ? AppColors.successBg
                            : const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        _premiumActive
                            ? Icons.workspace_premium
                            : Icons.workspace_premium_outlined,
                        color: _premiumActive
                            ? AppColors.success
                            : const Color(0xFFB45309),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _premiumActive
                                ? 'Premium Active'
                                : 'Go Premium',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _premiumActive
                                ? 'Unlimited scans unlocked'
                                : 'Unlimited scans · Priority analysis',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: _premiumActive
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: _premiumToggling
                                  ? null
                                  : _togglePremium,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                elevation: 0,
                              ),
                              child: _premiumToggling
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'UPGRADE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ],

              const AppSectionTitle('Account'),
              const SizedBox(height: 12),

              _SettingItem(
                icon: Icons.info_outline,
                title: 'About & How It Works',
                desc: '4 detection models explained',
                onTap: () => Navigator.pushNamed(context, '/how_it_works'),
              ),
              _SettingItem(
                icon: Icons.notifications_none,
                title: 'Notifications',
                desc: 'Email, alerts & updates',
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
              _SettingItem(
                icon: Icons.security,
                title: 'Privacy & Security',
                desc: 'Privacy, sessions & password',
                onTap: () => Navigator.pushNamed(context, '/privacy'),
              ),
              _SettingItem(
                icon: Icons.logout,
                title: 'Sign Out',
                desc: 'Log out of your account',
                isDestructive: true,
                onTap: () => _confirmSignOut(context),
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'ChitraVision AI • Version 2.4',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String num;
  final String name;
  final Color color;

  const _ProfileStatItem({
    required this.num,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          num,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor =
        isDestructive ? AppColors.danger : AppColors.primary;
    final Color iconBgColor =
        isDestructive ? AppColors.dangerBg : AppColors.surfaceAlt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: mainColor, size: 21),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDestructive
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
