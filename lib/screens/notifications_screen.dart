import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _keyEmail = 'notif_email';
  static const String _keyAlerts = 'notif_alerts';
  static const String _keyActivity = 'notif_activity';
  static const String _keySecurity = 'notif_security';

  bool _emailEnabled = true;
  bool _alertsEnabled = true;
  bool _activityEnabled = false;
  bool _securityEnabled = true;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _emailEnabled = prefs.getBool(_keyEmail) ?? true;
      _alertsEnabled = prefs.getBool(_keyAlerts) ?? true;
      _activityEnabled = prefs.getBool(_keyActivity) ?? false;
      _securityEnabled = prefs.getBool(_keySecurity) ?? true;
    });
  }

  void _onToggleChanged() {
    setState(() => _hasChanges = true);
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEmail, _emailEnabled);
    await prefs.setBool(_keyAlerts, _alertsEnabled);
    await prefs.setBool(_keyActivity, _activityEnabled);
    await prefs.setBool(_keySecurity, _securityEnabled);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notification settings saved successfully!',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
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
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
            Switch(
              value: value,
              onChanged: (v) {
                onChanged(v);
                _onToggleChanged();
              },
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
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
        leading: _buildBackButton(context),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose which notifications you want to receive. You can change these anytime.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              const AppSectionTitle('Preferences'),
              const SizedBox(height: 12),

              _buildToggle(
                icon: Icons.mail_outline,
                title: 'Email Notifications',
                desc: 'Receive summaries and alerts by email',
                value: _emailEnabled,
                onChanged: (v) => setState(() => _emailEnabled = v),
              ),
              _buildToggle(
                icon: Icons.priority_high,
                title: 'Important Alerts',
                desc: 'Critical updates about your account and scans',
                value: _alertsEnabled,
                onChanged: (v) => setState(() => _alertsEnabled = v),
              ),
              _buildToggle(
                icon: Icons.notifications_active_outlined,
                title: 'Activity Updates',
                desc: 'New scan results and weekly activity reports',
                value: _activityEnabled,
                onChanged: (v) => setState(() => _activityEnabled = v),
              ),
              _buildToggle(
                icon: Icons.shield_outlined,
                title: 'Security Notifications',
                desc: 'Login alerts, password changes, and security tips',
                value: _securityEnabled,
                onChanged: (v) => setState(() => _securityEnabled = v),
              ),

              const SizedBox(height: 8),

              AppPrimaryButton(
                label: _hasChanges ? 'Save Changes' : 'Saved',
                icon: Icons.save_outlined,
                enabled: _hasChanges,
                loading: _isSaving,
                onPressed: _saveChanges,
              ),

              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Your preferences are saved securely on this device',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBackButton(BuildContext context) {
  return Padding(
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
  );
}
