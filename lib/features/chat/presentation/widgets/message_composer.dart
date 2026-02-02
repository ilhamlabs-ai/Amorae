import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Message composer widget with image attachment support
class MessageComposer extends ConsumerStatefulWidget {
  final Function(String content, List<File> images) onSend;

  const MessageComposer({
    super.key,
    required this.onSend,
  });

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      // Handle error
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;

    widget.onSend(text, List.from(_selectedImages));
    _controller.clear();
    setState(() {
      _selectedImages.clear();
      _hasText = false;
    });
  }

  bool get _canSend => _hasText || _selectedImages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected images preview
          if (_selectedImages.isNotEmpty) ...[
            _buildImagePreview(),
            const SizedBox(height: 8),
          ],
          
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attach button
              _buildAttachButton(),
              
              const SizedBox(width: 8),
              
              // Text input
              Expanded(
                child: _buildTextInput(),
              ),
              
              const SizedBox(width: 8),
              
              // Send button
              _buildSendButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImages[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
        },
      ),
    );
  }

  Widget _buildAttachButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, -120),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.surface,
      onSelected: (value) {
        if (value == 'gallery') {
          _pickImage();
        } else if (value == 'camera') {
          _takePhoto();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'gallery',
          child: Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text('Gallery', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'camera',
          child: Row(
            children: [
              const Icon(Icons.camera_alt_outlined,
                  color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text('Camera', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: 5,
      minLines: 1,
      style: AppTextStyles.bodyMedium,
      cursorColor: AppColors.accent,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: 'Type a message...',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _canSend ? _send : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: _canSend ? AppColors.primaryGradient : null,
          color: _canSend ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _canSend
              ? [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.send_rounded,
          color: _canSend ? AppColors.textOnPrimary : AppColors.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
