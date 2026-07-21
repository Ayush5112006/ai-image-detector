import 'package:flutter/material.dart';

class DetectScreen extends StatelessWidget {
  const DetectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text(
          'Choose a Model',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the detection model best suited for your media type.',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 20),
            _ModelListItem(
              number: 'Model 01',
              title: 'AI Image Detector',
              description: 'DALL-E • Midjourney • SD',
              icon: Icons.image,
              onTap: () => Navigator.pushNamed(context, '/model_detail', arguments: '01'),
            ),
            _ModelListItem(
              number: 'Model 02',
              title: 'Face Deepfake',
              description: 'Face-swap detection',
              icon: Icons.face,
              onTap: () => Navigator.pushNamed(context, '/model_detail', arguments: '02'),
            ),
            _ModelListItem(
              number: 'Model 03',
              title: 'Video Analyzer',
              description: 'Frame-by-frame video',
              icon: Icons.movie_outlined,
              onTap: () => Navigator.pushNamed(context, '/model_detail', arguments: '03'),
            ),
            _ModelListItem(
              number: 'Model 04',
              title: 'AI Content Classifier',
              description: 'Multi-modal synthetic',
              icon: Icons.auto_awesome,
              onTap: () => Navigator.pushNamed(context, '/model_detail', arguments: '04'),
            ),
          ],
        ),
      ),
    );
  }
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF007AFF), size: 24),
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
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFBBBBBB), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
