import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  static const String _keyVisibility = 'privacy_visibility';
  static const String _keyDataSharing = 'privacy_data_sharing';
  static const String _keyTwoFactor = 'privacy_2fa';

  bool _profileVisible = true;
  bool _dataSharing = false;
  bool _twoFactor = false;

  final List<Map<String, dynamic>> _sessions = [
    {
      'device': 'ChitraVision Android',
      'detail': 'Current device • Active now',
      'icon': Icons.smartphone,
      'current': true,
    },
    {
      'device': 'Windows • Chrome',
      'detail': 'Last active 2 hours ago',
      'icon': Icons.laptop_mac,
      'current': false,
    },
    {
      'device': 'iPhone 15 Pro',
      'detail': 'Last active 3 days ago',
      'icon': Icons.phone_iphone,
      'current': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _profileVisible = prefs.getBool(_keyVisibility) ?? true;
      _dataSharing = prefs.getBool(_keyDataSharing) ?? false;
      _twoFactor = prefs.getBool(_keyTwoFactor) ?? false;
    });
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showSnack(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? AppColors.success : AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _confirm(
    String title,
    String message, {
    String confirmLabel = 'Confirm',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(
              destructive ? Icons.warning_amber_rounded : Icons.help_outline,
              color: destructive ? AppColors.danger : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? AppColors.danger : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text('Change Password'),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: obscureCurrent,
                    decoration: AppInputDecoration.build(
                      hint: 'Current password',
                      label: 'Current password',
                      icon: Icons.password,
                      suffix: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your current password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: AppInputDecoration.build(
                      hint: 'At least 6 characters',
                      label: 'New password',
                      icon: Icons.lock_reset,
                      suffix: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a new password';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: AppInputDecoration.build(
                      hint: 'Repeat new password',
                      label: 'Confirm new password',
                      icon: Icons.verified_user_outlined,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirm your new password';
                      if (v != newCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      _showSnack('Password updated successfully!');
    }
  }

  Future<void> _logoutSession(int index) async {
    final session = _sessions[index];
    final ok = await _confirm(
      'Log out of this device?',
      'You will be signed out of "${session['device']}". You can sign back in anytime.',
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _sessions.removeAt(index));
    _showSnack('Logged out of ${session['device']}');
  }

  Future<void> _logoutAllDevices() async {
    final ok = await _confirm(
      'Log out of all devices?',
      'This will sign you out everywhere except this device. You may need to re-enter your password on other devices.',
      confirmLabel: 'Log Out All',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _sessions.removeWhere((s) => !(s['current'] as bool));
    });
    _showSnack('Logged out of all other devices');
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirm(
      'Delete your account?',
      'This action is permanent. All your scan history, settings, and account data will be removed and cannot be recovered.',
      confirmLabel: 'Delete Account',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _showSnack('Account deletion request submitted');
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: AppSectionTitle(text),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SettingsToggle(
        icon: icon,
        title: title,
        desc: desc,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
    bool destructive = false,
    Color? accent,
  }) {
    final Color color = destructive ? AppColors.danger : (accent ?? AppColors.primary);
    final Color bg = destructive ? AppColors.dangerBg : AppColors.surfaceAlt;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: destructive ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 32),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Your privacy is protected. We only use your data to improve deepfake detection accuracy.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _sectionHeader('Privacy Settings'),
              _toggleTile(
                icon: Icons.visibility_outlined,
                title: 'Profile Visibility',
                desc: 'Allow others to see your profile and activity',
                value: _profileVisible,
                onChanged: (v) {
                  _profileVisible = v;
                  _saveToggle(_keyVisibility, v);
                  _showSnack(v ? 'Profile is now visible' : 'Profile is now private');
                },
              ),
              _toggleTile(
                icon: Icons.share_outlined,
                title: 'Data Sharing Preferences',
                desc: 'Share anonymized data to improve AI models',
                value: _dataSharing,
                onChanged: (v) {
                  _dataSharing = v;
                  _saveToggle(_keyDataSharing, v);
                  _showSnack(v ? 'Anonymized data sharing enabled' : 'Data sharing disabled');
                },
              ),

              _sectionHeader('Account Security'),
              _toggleTile(
                icon: Icons.fingerprint,
                title: 'Two-Factor Authentication',
                desc: 'Add an extra layer of security to your account',
                value: _twoFactor,
                onChanged: (v) {
                  _twoFactor = v;
                  _saveToggle(_keyTwoFactor, v);
                  _showSnack(v ? 'Two-factor authentication enabled' : 'Two-factor authentication disabled');
                },
              ),

              _sectionHeader('Login & Sessions'),
              ..._sessions.asMap().entries.map((entry) {
                final index = entry.key;
                final session = entry.value;
                final bool isCurrent = session['current'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(
                            session['icon'] as IconData,
                            color: AppColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      session['device'] as String,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Current',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                session['detail'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrent)
                          TextButton(
                            onPressed: () => _logoutSession(index),
                            child: const Text(
                              'Log out',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
              AppSecondaryButton(
                label: 'Log Out of All Devices',
                icon: Icons.devices_other,
                destructive: true,
                onPressed: _logoutAllDevices,
              ),
              const SizedBox(height: 8),

              _sectionHeader('Password / Authentication'),
              _actionTile(
                icon: Icons.lock_reset,
                title: 'Change Password',
                desc: 'Update your account password',
                onTap: _changePassword,
              ),

              _sectionHeader('About App & Security'),
              _actionTile(
                icon: Icons.description_outlined,
                title: 'Privacy Policy',
                desc: 'Read our full privacy & security policy',
                onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
              ),

              const SizedBox(height: 16),
              AppSecondaryButton(
                label: 'Delete Account',
                icon: Icons.delete_forever_outlined,
                destructive: true,
                onPressed: _deleteAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<_SettingsToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SettingsToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(widget.icon, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
