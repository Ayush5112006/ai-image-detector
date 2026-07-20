import 'package:flutter/material.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF333333), size: 18),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'How It Works',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
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
                  colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield,
                      color: Colors.white,
                      size: 32,
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
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              '4 DETECTION MODELS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF999999),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Model Details
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
            const Text(
              'TECH STACK',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF999999),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TechTag(text: 'React Native'),
                _TechTag(text: 'Expo'),
                _TechTag(text: 'FastAPI'),
                _TechTag(text: 'MongoDB'),
                _TechTag(text: 'Gemini Vision'),
                _TechTag(text: 'PyTorch'),
                _TechTag(text: 'OpenCV'),
                _TechTag(text: 'HuggingFace'),
              ],
            ),
            const SizedBox(height: 30),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
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
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((t) => _TechTag(text: t)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechTag extends StatelessWidget {
  final String text;

  const _TechTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF007AFF),
        ),
      ),
    );
  }
}
