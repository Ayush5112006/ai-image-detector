import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/profile_avatar.dart';

class DetectScreen extends StatefulWidget {
  const DetectScreen({super.key});

  @override
  State<DetectScreen> createState() => _DetectScreenState();
}

class _DetectScreenState extends State<DetectScreen> {
  static const List<_ModelItem> _models = [
    _ModelItem(
      number: 'Model 01',
      title: 'AI Image Detector',
      description: 'DALL-E • Midjourney • SD',
      icon: Icons.image,
      detail: '01',
    ),
    _ModelItem(
      number: 'Model 02',
      title: 'Face Deepfake',
      description: 'Face-swap detection',
      icon: Icons.face,
      detail: '02',
    ),
    _ModelItem(
      number: 'Model 03',
      title: 'Video Analyzer',
      description: 'Frame-by-frame video',
      icon: Icons.movie_outlined,
      detail: '03',
    ),
    _ModelItem(
      number: 'Model 04',
      title: 'AI Content Classifier',
      description: 'Multi-modal synthetic',
      icon: Icons.auto_awesome,
      detail: '04',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ModelItem> get _filteredModels {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _models;
    return _models.where((m) {
      return m.title.toLowerCase().contains(query) ||
          m.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final models = _filteredModels;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
          child: ProfileAvatar(
            name: 'Ayush',
            onTap: () => Navigator.pushNamed(context, '/profile_details'),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: AppInputDecoration.build(
                hint: 'Search detection models...',
                icon: Icons.search,
              ),
            ),
            const SizedBox(height: 16),
            if (models.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No detection models found',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...models.map(
                (m) => _ModelListItem(
                  number: m.number,
                  title: m.title,
                  description: m.description,
                  icon: m.icon,
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/model_detail',
                    arguments: m.detail,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModelItem {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final String detail;

  const _ModelItem({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.detail,
  });
}

class _ModelListItem extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ModelListItem({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
