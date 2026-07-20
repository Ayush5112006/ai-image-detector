import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Dsa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'dsa06112006@gmail.com',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProfileStatItem(
                        num: '0',
                        name: 'Total Scans',
                        color: const Color(0xFF007AFF),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                      const _ProfileStatItem(
                        num: '0',
                        name: 'Fakes Found',
                        color: Color(0xFFFF3B30),
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFE0E0E0)),
                      const _ProfileStatItem(
                        num: '0',
                        name: 'Cleared',
                        color: Color(0xFF34C759),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Level Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level 1 Analyst',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            '0% to next',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          value: 0.0,
                          backgroundColor: Color(0xFFF0F2F5),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account Options
              const Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF999999),
                  letterSpacing: 0.5,
                ),
              ),
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
                desc: 'Push settings',
                onTap: () {},
              ),
              _SettingItem(
                icon: Icons.security,
                title: 'Privacy & Security',
                desc: 'Data & sessions',
                onTap: () {},
              ),
              _SettingItem(
                icon: Icons.logout,
                title: 'Sign Out',
                desc: 'Log out of account',
                isDestructive: true,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF999999),
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
    final Color mainColor = isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF007AFF);
    final Color iconBgColor = isDestructive ? const Color(0xFFFFE8E8) : const Color(0xFFF0F2F5);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: mainColor, size: 20),
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
                        color: isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
