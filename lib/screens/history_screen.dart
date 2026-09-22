import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/skeleton.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.onStartDetection, this.active = true});

  /// Switches to the Detect tab when the user taps the CTA in the empty state.
  final VoidCallback? onStartDetection;

  /// Whether this tab is the one currently visible. When it flips to
  /// `true`, the history silently reloads so newly-run scans appear.
  final bool active;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _activeChipIndex = 0;
  final List<String> _chips = ['All', 'AI Image', 'Face', 'Video', 'Content'];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  String _name = '';

  List<Map<String, dynamic>> _detections = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadDetections();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final name = prefs.getString('profile_name');
    if (name != null && name.isNotEmpty) {
      setState(() => _name = name);
    }
  }

  @override
  void didUpdateWidget(HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _loadDetections(showLoader: false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDetections({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      _error = null;
    }
    try {
      final detections = await ApiService.getDetections();
      if (!mounted) return;
      setState(() {
        _detections = detections;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _deleteDetection(Map<String, dynamic> detection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.danger, size: 24),
            SizedBox(width: 10),
            Text('Delete Scan'),
          ],
        ),
        content: const Text(
          'Remove this scan from your history?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteDetection(detection['_id'].toString());
      if (!mounted) return;
      setState(() {
        _detections.removeWhere(
          (d) => d['_id'].toString() == detection['_id'].toString(),
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredDetections {
    List<Map<String, dynamic>> list = List.of(_detections);

    final category = _categoryForChip(_activeChipIndex);
    if (category != null) {
      list = list.where((d) => d['category'] == category).toList();
    }

    final query = _query.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((d) {
        final fileName = (d['fileName'] ?? '').toString().toLowerCase();
        final label = (d['resultLabel'] ?? '').toString().toLowerCase();
        final model = (d['modelName'] ?? '').toString().toLowerCase();
        return fileName.contains(query) ||
            label.contains(query) ||
            model.contains(query);
      }).toList();
    }
    return list;
  }

  String? _categoryForChip(int index) {
    switch (index) {
      case 1:
        return 'image';
      case 2:
        return 'face';
      case 3:
        return 'video';
      case 4:
        return 'content';
      default:
        return null;
    }
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final date = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final sameDay = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final hh = date.hour.toString().padLeft(2, '0');
      final mm = date.minute.toString().padLeft(2, '0');
      final month = const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][date.month - 1];
      final time = '$hh:$mm';
      if (sameDay) return 'Today · $time';
      return '${date.day} $month ${date.year} · $time';
    } catch (_) {
      return '';
    }
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'face':
        return Icons.face;
      case 'video':
        return Icons.movie_outlined;
      case 'content':
        return Icons.auto_awesome;
      default:
        return Icons.image_outlined;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'face':
        return 'Face';
      case 'video':
        return 'Video';
      case 'content':
        return 'Content';
      default:
        return 'AI Image';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDetections;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  ProfileAvatar(
                    name: _name.isEmpty ? null : _name,
                    onTap: () =>
                        Navigator.pushNamed(context, '/profile_details'),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ARCHIVE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scan History',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: AppInputDecoration.build(
                  hint: 'Search scans...',
                  icon: Icons.search,
                ),
              ),
              const SizedBox(height: 16),

              // Filter chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _chips.length,
                  itemBuilder: (context, index) {
                    final bool isActive = _activeChipIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _activeChipIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary : Colors.white,
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              _chips[index],
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: _buildBody(filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filtered) {
    if (_loading) {
      return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) =>
            const _SkeletonDetectionCard(),
      );
    }

    if (_error != null && _detections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: AppSecondaryButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: _loadDetections,
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_outlined,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _detections.isEmpty ? 'No scans yet' : 'No matches found',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _detections.isEmpty
                    ? 'Your analysis history will appear here once you\nrun your first detection.'
                    : 'Try a different search or filter.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (_detections.isEmpty) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: 200,
                  child: AppPrimaryButton(
                    label: 'Start Detecting',
                    icon: Icons.shield_outlined,
                    onPressed: widget.onStartDetection,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDetections,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final detection = filtered[index];
          return _DetectionCard(
            detection: detection,
            dateLabel: _formatDate(detection['createdAt']?.toString()),
            icon: _iconForCategory((detection['category'] ?? 'image').toString()),
            categoryLabel:
                _categoryLabel((detection['category'] ?? 'image').toString()),
            onDelete: () => _deleteDetection(detection),
          );
        },
      ),
    );
  }
}

class _SkeletonDetectionCard extends StatelessWidget {
  const _SkeletonDetectionCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppSkeleton.box(
              width: 48,
              height: 48,
              radius: AppRadius.md,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton.box(width: 150),
                  const SizedBox(height: 8),
                  AppSkeleton.box(width: 100, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppSkeleton.box(width: 56, height: 20, radius: 20),
                const SizedBox(height: 8),
                AppSkeleton.box(width: 34, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final Map<String, dynamic> detection;
  final String dateLabel;
  final IconData icon;
  final String categoryLabel;
  final VoidCallback onDelete;

  const _DetectionCard({
    required this.detection,
    required this.dateLabel,
    required this.icon,
    required this.categoryLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAI = detection['verdict'] == 'AI';
    final Color verdictColor = isAI ? AppColors.danger : AppColors.success;
    final String fileName =
        (detection['fileName'] ?? '').toString().isNotEmpty
            ? (detection['fileName'] ?? '').toString()
            : (detection['modelName'] ?? 'Scan').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateLabel.isEmpty
                        ? categoryLabel
                        : '$categoryLabel · $dateLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAI
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAI ? 'FAKE' : 'REAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: verdictColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(detection['confidence'] ?? 0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: verdictColor,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}