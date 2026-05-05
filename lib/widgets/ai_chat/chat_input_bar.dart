import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/chat_translations.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final File? selectedImage;
  final bool isLoading;
  final String selectedLanguage;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.selectedImage,
    required this.isLoading,
    required this.selectedLanguage,
    required this.onPickImage,
    required this.onClearImage,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 8, top: 12, bottom: 24),
      decoration: const BoxDecoration(
          color: AppColors.cardBg,
          border: Border(top: BorderSide(color: Colors.white10)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
              child: Stack(
                children: [
                  Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: -4, right: -4,
                    child: IconButton(icon: const Icon(Icons.cancel, color: Colors.white, size: 20), onPressed: onClearImage),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined, color: AppColors.textMuted),
                onPressed: isLoading ? null : onPickImage,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: AppColors.scaffoldBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    minLines: 1, maxLines: 4,
                    decoration: InputDecoration(
                        hintText: ChatTranslations.uiStrings[selectedLanguage]!['hint'],
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                    ),
                    onSubmitted: isLoading ? null : (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    onPressed: isLoading ? null : onSend
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}