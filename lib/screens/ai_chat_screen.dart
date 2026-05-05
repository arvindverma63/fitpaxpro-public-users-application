import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_api_service.dart';
import '../models/ai_models.dart';
import '../theme/app_colors.dart';
import '../utils/chat_translations.dart';
import '../widgets/ai_chat/typing_indicator_bubble.dart';
import '../widgets/ai_chat/chat_message_bubble.dart';
import '../widgets/ai_chat/ai_profile_sheet.dart';
import '../widgets/ai_chat/chat_app_bar.dart';
import '../widgets/ai_chat/suggestions_bar.dart';
import '../widgets/ai_chat/chat_input_bar.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final AiApiService _aiService = AiApiService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  List<String> _currentSuggestions = [];
  bool _isLoading = false;
  String _sessionId = 'default';
  File? _selectedImage;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('auth_token') ?? 'guest_session';

    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'English';
    });

    final String? localCache = prefs.getString('chat_cache_$_sessionId');
    if (localCache != null) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(jsonDecode(localCache));
      });
      _scrollToBottom();
    }

    if (_messages.isEmpty) {
      _addMessage(
          text: ChatTranslations.uiStrings[_selectedLanguage]!['welcome']!,
          isUser: false
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
    List<dynamic>? nutrition,
    String? imagePath
  }) {
    setState(() {
      _messages.add({
        "text": text,
        "isUser": isUser,
        "isPlan": isPlan,
        "exercises": exercises,
        "nutrition": nutrition,
        "imagePath": imagePath
      });
    });
    _saveChatLocally();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _handleSubmitted([String? customText]) async {
    final text = customText ?? _textController.text;
    if (text.trim().isEmpty && _selectedImage == null) return;

    final String messageText = text.trim();
    final File? imageToSend = _selectedImage;

    final List<Map<String, dynamic>> historyToSend = List.from(_messages);

    _textController.clear();
    setState(() {
      _currentSuggestions = [];
      _selectedImage = null;
      _isLoading = true;
    });

    _addMessage(text: messageText, isUser: true, imagePath: imageToSend?.path);

    String? imageBase64;
    if (imageToSend != null) {
      final bytes = await imageToSend.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    final String instruction = _selectedLanguage != 'English'
        ? "\n\n[Important: Please provide your entire response in $_selectedLanguage]"
        : "";

    final request = ChatRequest(message: messageText + instruction, sessionId: _sessionId);

    final response = await _aiService.sendMessage(
      request,
      imageBase64: imageBase64,
      history: historyToSend,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null) {
        _addMessage(
            text: response.reply,
            isUser: false,
            isPlan: response.kind == 'plan',
            exercises: response.exerciseExamples?.map((e) => e.toJson()).toList(),
            nutrition: response.nutritionExamples?.map((n) => n.toJson()).toList()
        );
        setState(() => _currentSuggestions = response.suggestions ?? []);
      } else {
        _addMessage(text: "Connection lost. Please check if your AI server is running.", isUser: false);
      }
    }
  }

  Future<void> _generateMasterPlan() async {
    _addMessage(text: ChatTranslations.uiStrings[_selectedLanguage]!['plan_prompt']!, isUser: true);
    setState(() => _isLoading = true);

    final response = await _aiService.generatePlan(_sessionId);

    if (mounted) {
      setState(() => _isLoading = false);
      if (response != null && response['ok'] == true) {
        String fullResponse = response['reply'] ?? '';
        if (response['weekly_guidance'] != null) {
          fullResponse += '\n\n🏋️‍♂️ **Weekly Guidance:**\n${response['weekly_guidance']}';
        }
        if (response['meal_guidance'] != null) {
          fullResponse += '\n\n🥦 **Nutrition Guidance:**\n${response['meal_guidance']}';
        }
        _addMessage(
            text: fullResponse,
            isUser: false,
            isPlan: true,
            exercises: response['exercise_examples'],
            nutrition: response['nutrition_examples']
        );
        setState(() => _currentSuggestions = response['suggestions'] != null ? List<String>.from(response['suggestions']) : []);
      } else {
        _addMessage(text: "Failed to generate master plan. Check your backend connection.", isUser: false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut
        );
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
          onProfileUpdated: (goal, diet) => _handleSubmitted("I just updated my profile to focus on $goal with a $diet diet. Acknowledge this.")
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: ChatAppBar(
        isLoading: _isLoading,
        selectedLanguage: _selectedLanguage,
        onGeneratePlan: _generateMasterPlan,
        onOpenProfile: _showProfileManager,
        onClearChat: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('chat_cache_$_sessionId');
          setState(() {
            _messages.clear();
            _currentSuggestions.clear();
            _selectedImage = null;
          });
          _initializeChat();
        },
        onLanguageChanged: (lang) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('app_language', lang);
          setState(() => _selectedLanguage = lang);
          _addMessage(text: "Language changed to $lang. How can I help you?", isUser: false);
        },
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
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: TypingIndicatorBubble()),
          SuggestionsBar(
              suggestions: _currentSuggestions,
              isLoading: _isLoading,
              onSuggestionSelected: _handleSubmitted
          ),
          ChatInputBar(
            controller: _textController,
            selectedImage: _selectedImage,
            isLoading: _isLoading,
            selectedLanguage: _selectedLanguage,
            onPickImage: _pickImage,
            onClearImage: () => setState(() => _selectedImage = null),
            onSend: () => _handleSubmitted(),
          ),
        ],
      ),
    );
  }
}