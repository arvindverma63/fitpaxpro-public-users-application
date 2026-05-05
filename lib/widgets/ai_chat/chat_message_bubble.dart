import 'dart:io'; // <-- NEW: Required to read the local image file
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../services/pdf_service.dart';
import '../../services/ai_api_service.dart';
import '../../theme/app_colors.dart';

class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const ChatMessageBubble({super.key, required this.message});

  String _buildImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AiApiService.baseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message['isUser'];
    final bool isPlan = message['isPlan'] ?? false;
    final List<dynamic> exercises = message['exercises'] ?? [];
    final List<dynamic> nutrition = message['nutrition'] ?? [];
    final String? localImagePath = message['imagePath']; // <-- NEW: Grab the image path

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primaryLight.withOpacity(0.3), blurRadius: 8)]
              ),
              child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.auto_awesome, size: 14, color: Colors.white)
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [

                // --- CHAT BUBBLE (TEXT + USER IMAGE) ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.cardBg,
                    boxShadow: [if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // --- NEW: DISPLAY USER ATTACHED IMAGE ---
                      if (localImagePath != null && localImagePath.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(localImagePath),
                              width: 200, // Constrain the image size in the chat
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, color: Colors.white54, size: 40),
                            ),
                          ),
                        ),

                      // --- MARKDOWN TEXT ---
                      if (message['text'] != null && message['text'].toString().isNotEmpty)
                        MarkdownBlock(
                          data: message['text'],
                          config: MarkdownConfig(
                            configs: [
                              PConfig(textStyle: TextStyle(color: isUser ? Colors.white : AppColors.textMain, fontSize: 15, height: 1.4)),
                              H1Config(style: TextStyle(color: isUser ? Colors.white : AppColors.primaryLight, fontSize: 22, fontWeight: FontWeight.bold)),
                              H2Config(style: TextStyle(color: isUser ? Colors.white : AppColors.primaryLight, fontSize: 18, fontWeight: FontWeight.bold)),
                              H3Config(style: TextStyle(color: isUser ? Colors.white : AppColors.primaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
                              TableConfig(
                                headerStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                bodyStyle: const TextStyle(color: AppColors.textMain),
                                border: TableBorder.all(color: Colors.white24, width: 1),
                                wrapper: (tableWidget) => SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: tableWidget,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // --- EXERCISES CAROUSEL ---
                if (exercises.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(" Recommended Exercises", style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 170,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: exercises.length,
                        itemBuilder: (context, idx) {
                          final ex = exercises[idx];
                          return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      child: CachedNetworkImage(
                                        imageUrl: _buildImageUrl(ex['gif_url'] ?? ''),
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (context, url, error) => Container(color: Colors.black26, child: const Icon(Icons.image_not_supported, color: Colors.white24)),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ex['name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text('Target: ${ex['muscles'] ?? 'Full Body'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  )
                                ],
                              )
                          );
                        }
                    ),
                  )
                ],

                // --- NUTRITION TARGETS ---
                if (nutrition.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(" Nutrition Targets", style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: Column(
                      children: nutrition.map((n) => ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(n['name'].toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('P: ${n['protein']}g • C: ${n['carbohydrate']}g • F: ${n['fat']}g', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text('${n['calories']} kcal', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      )).toList(),
                    ),
                  )
                ],

                // --- EXPORT PDF BUTTON ---
                if (isPlan) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Export Plan to PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () => PdfService.generateAndSharePlan(message),
                    ),
                  )
                ]
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 26),
        ],
      ),
    );
  }
}