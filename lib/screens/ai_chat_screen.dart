import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_api_service.dart';
import '../models/ai_models.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_chat/chat_message_bubble.dart';
import '../widgets/ai_chat/ai_profile_sheet.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiApiService _aiService = AiApiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  List<String> _currentSuggestions = [];
  bool _isLoading = false;
  String _sessionId = 'default';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('auth_token') ?? 'guest_session';

    final String? localCache = prefs.getString('chat_cache_$_sessionId');
    if (localCache != null) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(jsonDecode(localCache));
      });
      _scrollToBottom();
    }

    if (_messages.isEmpty) {
      _addMessage(
        text: "Hi there! I'm FitPax AI. I can build you a custom workout plan, track your nutrition, or adapt to your specific goals.\n\nTap the ✨ icon at the top to generate your Master Plan!",
        isUser: false,
      );
    }
  }

  Future<void> _saveChatLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_cache_$_sessionId', jsonEncode(_messages));
  }

  void _addMessage({
    required String text,
    required bool isUser,
    bool isPlan = false,
    List<dynamic>? exercises,
    List<dynamic>? nutrition
  }) {
    setState(() {
      _messages.add({
        "text": text,
        "isUser": isUser,
        "isPlan": isPlan,
        "exercises": exercises,
        "nutrition": nutrition,
      });
    });
    _saveChatLocally();
    _scrollToBottom();
  }

  // --- STANDARD CHAT ENDPOINT ---
  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    setState(() => _currentSuggestions = []);

    _addMessage(text: text.trim(), isUser: true);

    setState(() => _isLoading = true);
    _scrollToBottom();

    final request = ChatRequest(message: text.trim(), sessionId: _sessionId);
    final response = await _aiService.sendMessage(request);

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null) {
        _addMessage(
          text: response.reply,
          isUser: false,
          isPlan: response.kind == 'plan',
          exercises: response.exerciseExamples?.map((e) => e.toJson()).toList(),
          nutrition: response.nutritionExamples?.map((n) => n.toJson()).toList(),
        );
        setState(() {
          _currentSuggestions = response.suggestions ?? [];
        });
      } else {
        _addMessage(text: "Connection lost. Please try again.", isUser: false);
      }
    }
  }

  // --- NEW: RECOMMENDATION MASTER PLAN ENDPOINT ---
  Future<void> _generateMasterPlan() async {
    // 1. Add user message visually
    _addMessage(text: "Generate my ultimate fitness and nutrition master plan based on my profile.", isUser: true);

    setState(() => _isLoading = true);
    _scrollToBottom();

    // 2. Call the POST /recommend API
    final response = await _aiService.generatePlan(_sessionId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null && response['ok'] == true) {

        // 3. Combine the rich text fields into one beautiful response
        String fullResponse = response['reply'] ?? '';

        if (response['weekly_guidance'] != null) {
          fullResponse += '\n\n🏋️‍♂️ **Weekly Guidance:**\n${response['weekly_guidance']}';
        }
        if (response['meal_guidance'] != null) {
          fullResponse += '\n\n🥦 **Nutrition Guidance:**\n${response['meal_guidance']}';
        }

        // 4. Add the massive response bubble (which includes the PDF button automatically!)
        _addMessage(
          text: fullResponse,
          isUser: false,
          isPlan: true, // Triggers the PDF download button
          exercises: response['exercise_examples'],
          nutrition: response['nutrition_examples'],
        );

        setState(() {
          _currentSuggestions = response['suggestions'] != null
              ? List<String>.from(response['suggestions'])
              : [];
        });
      } else {
        _addMessage(text: "Failed to generate master plan. Check your connection.", isUser: false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showProfileManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.scaffoldBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => AiProfileSheet(
        sessionId: _sessionId,
        onProfileUpdated: (goal, diet) {
          _handleSubmitted("I just updated my profile to focus on $goal with a $diet diet. Acknowledge this.");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
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
          // --- NEW: THE MAGIC RECOMMENDATION BUTTON ---
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.auto_awesome, color: AppColors.primaryLight),
              tooltip: 'Generate Master Plan',
              onPressed: _isLoading ? null : _generateMasterPlan,
            ),
          ),

          // Profile Settings Button
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textMain),
            tooltip: 'AI Profile Settings',
            onPressed: _showProfileManager,
          ),

          // Clear Chat Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            color: AppColors.cardBg,
            onSelected: (value) async {
              if (value == 'clear') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('chat_cache_$_sessionId');
                setState(() {
                  _messages.clear();
                  _currentSuggestions.clear();
                });
                _initializeChat();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat History', style: TextStyle(color: Colors.redAccent))),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) => ChatMessageBubble(message: _messages[index]),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 24.0, bottom: 8.0, top: 4.0),
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Text('Calculating optimal plan...', style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
          if (_currentSuggestions.isNotEmpty && !_isLoading)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _currentSuggestions.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    side: const BorderSide(color: AppColors.primaryLight, width: 0.5),
                    label: Text(_currentSuggestions[index], style: const TextStyle(color: AppColors.primaryLight)),
                    onPressed: () => _handleSubmitted(_currentSuggestions[index]),
                  ),
                ),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 24),
      decoration: const BoxDecoration(color: AppColors.cardBg, border: Border(top: BorderSide(color: Colors.white10)), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.scaffoldBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                minLines: 1, maxLines: 4,
                decoration: const InputDecoration(hintText: 'Ask for a custom plan or exercise...', hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onSubmitted: _isLoading ? null : _handleSubmitted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: IconButton(icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20), onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text)),
          ),
        ],
      ),
    );
  }
}