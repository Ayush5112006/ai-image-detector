import 'package:flutter/material.dart';
import '../theme.dart';

/// Privacy & Security Policy document shown inside the
/// Privacy & Security screen's "About App & Security" section.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy & Security Policy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 20),

              _section(
                '1',
                'Our Commitment to Privacy',
                children: [
                  _paragraph(
                    'We respect your privacy and are committed to protecting the data you provide while using the Deepfake & AI-Generated Content Detection Platform.',
                  ),
                  _paragraph(
                    'Our platform is designed to analyze uploaded images and videos for deepfake and AI-generated content detection. We collect and process only the information required to provide and improve the detection service.',
                  ),
                  _boldHighlight(
                    'We do not sell, rent, or share your personal data or uploaded content with third parties for advertising or commercial purposes.',
                  ),
                ],
              ),

              _section(
                '2',
                'What Data We Collect',
                children: [
                  _paragraph(
                    'Depending on how you use the platform, we may process:',
                  ),
                  _subheading('Account Information'),
                  _bullets(const [
                    'Name',
                    'Email address',
                    'Password in securely hashed form',
                    'Account creation date',
                  ]),
                  _subheading('Detection Data'),
                  _paragraph(
                    'When you use the detection service, we may temporarily process:',
                  ),
                  _bullets(const [
                    'Uploaded images',
                    'Uploaded videos',
                    'File name and file type',
                    'Detection result',
                    'Confidence score',
                    'Detection date and time',
                  ]),
                  _subheading('Technical Information'),
                  _paragraph(
                    'We may collect limited technical information required for security and operation, such as:',
                  ),
                  _bullets(const [
                    'Browser information',
                    'Device information',
                    'IP address or security logs where necessary',
                  ]),
                ],
              ),

              _section(
                '3',
                'How We Use Your Data',
                children: [
                  _paragraph(
                    'Your data is used only for legitimate platform purposes, including:',
                  ),
                  _bullets(const [
                    'Providing deepfake detection services',
                    'Processing uploaded images and videos',
                    'Generating detection results',
                    'Maintaining your detection history',
                    'Protecting the platform against unauthorized access',
                    'Maintaining system security and reliability',
                    'Improving the functionality of the platform',
                  ]),
                  _boldHighlight(
                    'We do not use uploaded personal content for advertising.',
                  ),
                ],
              ),

              _section(
                '4',
                'Uploaded Images and Videos',
                children: [
                  _paragraph(
                    'Uploaded content is processed by our detection system to generate a result.',
                  ),
                  _paragraph('The processing flow is:'),
                  _flow(),
                  const SizedBox(height: 12),
                  _paragraph(
                    'Uploaded content is not intentionally made publicly accessible.',
                  ),
                  _paragraph(
                    'Where technically possible, temporary processing files should be deleted after detection is completed and are not retained longer than necessary.',
                  ),
                  _paragraph(
                    'Detection records may contain metadata such as the file name, result, confidence score, and timestamp according to the platform\'s configured retention policy.',
                  ),
                ],
              ),

              _section(
                '5',
                'No Selling or Unauthorized Sharing of Data',
                children: [
                  _paragraph('We do not:'),
                  _bullets(const [
                    'Sell user data',
                    'Rent user data',
                    'Sell uploaded images or videos',
                    'Use uploaded content for advertising',
                    'Publicly publish uploaded content',
                    'Give other users access to your private detection history',
                    'Share personal information with third parties unless required for legitimate operation, security, legal compliance, or with your consent',
                  ]),
                ],
              ),

              _section(
                '6',
                'Data Security',
                children: [
                  _paragraph(
                    'We use reasonable technical and organizational security measures to protect user information.',
                  ),
                  _paragraph('These measures may include:'),
                  _bullets(const [
                    'JWT-based authentication',
                    'Password hashing',
                    'Protected API endpoints',
                    'Role-based access control',
                    'Secure file upload validation',
                    'File type and size restrictions',
                    'Input validation',
                    'Secure database access',
                    'HTTPS/TLS for data transmission',
                    'Restricted administrator access',
                    'Protection against unauthorized API requests',
                    'Temporary file cleanup',
                  ]),
                  _paragraph(
                    'No online service can guarantee absolute security. We continuously work to reduce security risks and protect the platform and its users.',
                  ),
                ],
              ),

              _section(
                '7',
                'Authentication and Account Security',
                children: [
                  _paragraph(
                    'User accounts are protected using authentication mechanisms.',
                  ),
                  _paragraph(
                    'Passwords should never be stored in plain text. Authentication credentials are securely hashed before storage.',
                  ),
                  _paragraph(
                    'JWT tokens are used to authenticate authorized requests between the frontend and backend.',
                  ),
                  _paragraph(
                    'Users are responsible for keeping their login credentials confidential and should immediately report suspected unauthorized access.',
                  ),
                ],
              ),

              _section(
                '8',
                'Detection History',
                children: [
                  _paragraph(
                    'Authenticated users may access their own detection history.',
                  ),
                  _paragraph('Detection history may contain:'),
                  _bullets(const [
                    'File name',
                    'Detection type',
                    'Prediction',
                    'Confidence score',
                    'Date and time',
                  ]),
                  _paragraph(
                    'Users should not upload highly sensitive or confidential material unless they are authorized to do so.',
                  ),
                ],
              ),

              _section(
                '9',
                'Administrator Access',
                children: [
                  _paragraph(
                    'Administrative access is restricted to authorized personnel.',
                  ),
                  _paragraph(
                    'Administrators may access limited platform information for purposes such as:',
                  ),
                  _bullets(const [
                    'System management',
                    'Security monitoring',
                    'User management',
                    'Abuse prevention',
                    'Troubleshooting',
                    'Platform maintenance',
                  ]),
                  _paragraph(
                    'Administrators should not access user content unnecessarily.',
                  ),
                ],
              ),

              _section(
                '10',
                'Data Retention and Deletion',
                children: [
                  _paragraph('We follow a data-minimization approach.'),
                  _paragraph(
                    'Temporary uploaded files should be retained only for the time necessary to perform detection and should be deleted when they are no longer required.',
                  ),
                  _paragraph(
                    'Detection history may be retained for users who choose to keep their history.',
                  ),
                  _paragraph(
                    'Users may request deletion of their account and associated data, subject to applicable legal and operational requirements.',
                  ),
                ],
              ),

              _section(
                '11',
                'Third-Party AI Services',
                children: [
                  _paragraph(
                    'The platform may use machine-learning models and supporting infrastructure to perform detection.',
                  ),
                  _paragraph(
                    'The current detection system uses a Hugging Face Transformers model:',
                  ),
                  _modelChip('dima806/deepfake_vs_real_image_detection'),
                  const SizedBox(height: 12),
                  _paragraph(
                    'The model is used to analyze uploaded content and generate detection predictions.',
                  ),
                  _paragraph(
                    'Third-party infrastructure providers may process technical data as necessary to operate the platform. Such processing should be limited to the services required by the platform.',
                  ),
                ],
              ),

              _section(
                '12',
                'Important Detection Disclaimer',
                children: [
                  _paragraph(
                    'The detection result is an **AI-generated prediction**, not a guaranteed determination of authenticity.',
                  ),
                  _paragraph(
                    'A result such as **"Fake"** or **"Real"** should not be treated as absolute proof.',
                  ),
                  _paragraph(
                    'AI detection models can produce:',
                  ),
                  _bullets(const [
                    'False positives',
                    'False negatives',
                    'Incorrect confidence scores',
                  ]),
                  _paragraph(
                    'Users should independently verify important content before making legal, financial, employment, safety, or other high-impact decisions based solely on the detection result.',
                  ),
                ],
              ),

              _section(
                '13',
                'Children\'s Privacy',
                children: [
                  _paragraph(
                    'The platform is not intentionally designed to collect personal information from children without appropriate authorization.',
                  ),
                  _paragraph(
                    'Users should not upload content containing personal information of minors unless they have the appropriate rights or permission to do so.',
                  ),
                ],
              ),

              _section(
                '14',
                'Data Breach and Security Incidents',
                children: [
                  _paragraph(
                    'If a significant security incident affects user information, the platform will take reasonable steps to investigate, contain, and remediate the incident and provide notifications where required by applicable law.',
                  ),
                ],
              ),

              _section(
                '15',
                'User Rights',
                children: [
                  _paragraph(
                    'Subject to applicable law, users may have rights regarding their personal information, including:',
                  ),
                  _bullets(const [
                    'Accessing their account information',
                    'Requesting correction of inaccurate information',
                    'Requesting deletion of their account or data',
                    'Requesting information about how their data is processed',
                    'Withdrawing consent where applicable',
                  ]),
                  _paragraph(
                    'Requests can be submitted through the platform\'s designated support or privacy contact.',
                  ),
                ],
              ),

              _section(
                '16',
                'Changes to This Policy',
                children: [
                  _paragraph(
                    'We may update this Privacy & Security Policy when our services, technology, or legal requirements change.',
                  ),
                  _paragraph(
                    'The latest version will be made available on this page with an updated "Last Updated" date.',
                  ),
                ],
              ),

              const SizedBox(height: 8),
              _section('', 'Security Principles', children: [
                _principle('1. Privacy First',
                    'User information and uploaded content are treated as private.'),
                _principle('2. Data Minimization',
                    'Only information required to operate the service should be collected.'),
                _principle('3. Secure Processing',
                    'Uploaded content is processed through protected backend and ML services.'),
                _principle('4. Access Control',
                    'Users can access their own information, while administrative access is restricted.'),
                _principle('5. Transparency',
                    'Users should understand what data is collected, why it is used, and how it is protected.'),
              ]),

              const SizedBox(height: 24),
              _contactCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Colors.white, size: 32),
          SizedBox(height: 10),
          Text(
            'Deepfake & AI-Generated Content Detection Platform',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Last Updated: August 8, 2026',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String number, String title, {required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (number.isNotEmpty) ...[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        _parseBold(text),
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.55,
        ),
      ),
    );
  }

  Widget _boldHighlight(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Text.rich(
        _parseBold(text),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _subheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _bullets(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 5,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _flow() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Text(
        'User → Node.js Backend → FastAPI ML Service → Detection Model → Result → MongoDB',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _modelChip(String model) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_outlined,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              model,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _principle(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard() {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              const Text(
                'Contact',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'For privacy or security questions, users should contact the platform administrator through the official support channel provided by the application.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          const Text(
            'Deepfake & AI-Generated Content Detection Platform',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your content. Your privacy. Your security.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders **bold** markers inside a plain text string as bold spans.
  TextSpan _parseBold(String text) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: (i.isOdd)
              ? const TextStyle(fontWeight: FontWeight.w600)
              : null,
        ),
      );
    }
    return TextSpan(children: spans);
  }
}
