import 'package:flutter/material.dart';
import '../theme.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: Container(
          margin: const EdgeInsets.all(8),
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
        title: const Text(
          'How It Works',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ChitraVision AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 2.4 • Powered by Gemini Vision',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const AppSectionTitle('4 Detection Models'),
            const SizedBox(height: 12),

            const _HowItWorksModelDetail(
              num: '01',
              title: 'AI Image Detector',
              desc: 'Detects AI-generated images from DALL-E, Midjourney, Stable Diffusion using EfficientNet-v4.',
              tags: ['EfficientNet-v4', 'HuggingFace'],
            ),
            const _HowItWorksModelDetail(
              num: '02',
              title: 'Deepfake Face Detector',
              desc: 'Detects face-swapped images. Uses MTCNN for face detection + XceptionNet classifier.',
              tags: ['XceptionNet', 'FaceForensics++'],
            ),
            const _HowItWorksModelDetail(
              num: '03',
              title: 'Video Deepfake Analyzer',
              desc: 'Frame-by-frame analysis using OpenCV + per-frame inference with timeline report.',
              tags: ['EfficientNet', 'OpenCV'],
            ),
            const _HowItWorksModelDetail(
              num: '04',
              title: 'AI Content Classifier',
              desc: 'Multi-modal classifier using ViT for identifying synthetic AI-generated media.',
              tags: ['ViT Transformer', 'Multi-modal'],
            ),

            const SizedBox(height: 20),
            const AppSectionTitle('Tech Stack'),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TechTag('Flutter'),
                _TechTag('FastAPI'),
                _TechTag('MongoDB'),
                _TechTag('Gemini Vision'),
                _TechTag('PyTorch'),
                _TechTag('OpenCV'),
                _TechTag('HuggingFace'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksModelDetail extends StatelessWidget {
  final String num;
  final String title;
  final String desc;
  final List<String> tags;

  const _HowItWorksModelDetail({
    required this.num,
    required this.title,
    required this.desc,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: Text(
                  num,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags) _TechTag(tag),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TechTag extends StatelessWidget {
  final String text;

  const _TechTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
