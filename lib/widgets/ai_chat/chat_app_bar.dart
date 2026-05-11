import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/chat_translations.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoading;
  final String selectedLanguage;
  final VoidCallback onGeneratePlan;
  final VoidCallback onOpenProfile;
  final VoidCallback onClearChat;
  final Function(String) onLanguageChanged;

  const ChatAppBar({
    super.key,
    required this.isLoading,
    required this.selectedLanguage,
    required this.onGeneratePlan,
    required this.onOpenProfile,
    required this.onClearChat,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cardBg,
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.smart_toy_rounded, color: AppColors.primaryLight),
          SizedBox(width: 10),
          Text('FitPax Pro AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.primaryLight),
            onPressed: isLoading ? null : onGeneratePlan,
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.language_rounded, color: AppColors.textMain),
          color: AppColors.cardBg,
          onSelected: onLanguageChanged,
          itemBuilder: (context) => ChatTranslations.uiStrings.keys.map((lang) =>
              PopupMenuItem(
                  value: lang,
                  child: Text(lang, style: TextStyle(
                      color: selectedLanguage == lang ? AppColors.primaryLight : AppColors.textMain,
                      fontWeight: selectedLanguage == lang ? FontWeight.bold : FontWeight.normal
                  ))
              )
          ).toList(),
        ),
        IconButton(
          icon: Icon(Icons.tune_rounded, color: AppColors.textMain),
          onPressed: onOpenProfile,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          color: AppColors.cardBg,
          onSelected: (value) { if (value == 'clear') onClearChat(); },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'clear', child: Text('Clear Chat History', style: TextStyle(color: Colors.redAccent))),
          ],
        )
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}