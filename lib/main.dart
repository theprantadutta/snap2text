import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const ProviderScope(child: Snap2TextApp()));
}

class Snap2TextApp extends StatelessWidget {
  const Snap2TextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2Text',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Custom GlassMorphic Container
class GlassMorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Widget child;
  final Color? color;

  const GlassMorphicContainer({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color:
            color ??
            (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.2)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
}

// State Management
final imageProvider = StateProvider<File?>((ref) => null);
final extractedTextProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = ref.watch(imageProvider);
    final extractedText = ref.watch(extractedTextProvider);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    const Color(0xFFe3f2fd),
                    const Color(0xFFbbdefb),
                    const Color(0xFF90caf9),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: 30),

                // Main Content
                Expanded(
                  child: image == null
                      ? _buildWelcomeSection(context, ref)
                      : _buildResultSection(
                          context,
                          ref,
                          image,
                          extractedText,
                          isLoading,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GlassMorphicContainer(
      width: double.infinity,
      height: 80,
      borderRadius: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_rounded,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Snap2Text',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Welcome Card
        GlassMorphicContainer(
          width: double.infinity,
          height: 200,
          borderRadius: 25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.text_fields_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Extract text from any image',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo or pick from gallery',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: () => _pickImage(ref, ImageSource.camera),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _pickImage(ref, ImageSource.gallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassMorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(
    BuildContext context,
    WidgetRef ref,
    File image,
    String extractedText,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview
        GlassMorphicContainer(
          width: double.infinity,
          height: 200,
          borderRadius: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Results Section
        Expanded(
          child: GlassMorphicContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_snippet_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Extracted Text',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Extracting text...'),
                              ],
                            ),
                          )
                        : extractedText.isEmpty
                        ? const Center(
                            child: Text(
                              'No text found in the image',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: SelectableText(
                              extractedText,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                  ),

                  if (extractedText.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextActionButton(
                            context,
                            icon: Icons.copy_rounded,
                            label: 'Copy',
                            onTap: () => _copyText(context, extractedText),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextActionButton(
                            context,
                            icon: Icons.share_rounded,
                            label: 'Share',
                            onTap: () => _shareText(extractedText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // New Photo Button
        _buildActionButton(
          context,
          icon: Icons.add_a_photo_rounded,
          label: 'New Photo',
          onTap: () => _resetAndPickNew(ref),
        ),
      ],
    );
  }

  Widget _buildTextActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        ref.read(imageProvider.notifier).state = imageFile;
        ref.read(extractedTextProvider.notifier).state = '';
        await _extractText(ref, imageFile);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
    }
  }

  Future<void> _extractText(WidgetRef ref, File imageFile) async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      final InputImage inputImage = InputImage.fromFile(imageFile);
      final TextRecognizer textRecognizer = TextRecognizer();

      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      ref.read(extractedTextProvider.notifier).state = recognizedText.text;

      await textRecognizer.close();
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting text: $e');
      }
      ref.read(extractedTextProvider.notifier).state = 'Error extracting text';
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Text copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareText(String text) {
    Share.share(text, subject: 'Text extracted by Snap2Text');
  }

  void _resetAndPickNew(WidgetRef ref) {
    ref.read(imageProvider.notifier).state = null;
    ref.read(extractedTextProvider.notifier).state = '';
    ref.read(isLoadingProvider.notifier).state = false;
  }
}
