import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/question.dart';
import '../providers/ai_provider.dart';
import '../services/firestore_service.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AiProvider _aiProvider;

  @override
  void initState() {
    super.initState();
    _aiProvider = context.read<AiProvider>();
    _aiProvider.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _aiProvider.removeListener(_scrollToBottom);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// চ্যাটে নতুন মেসেজ আসলে অটোমেটিক নিচে স্ক্রোল করা
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// মেসেজ সেন্ড করা
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _aiProvider.isGenerating) return;

    _aiProvider.sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  /// চ্যাট বাবুল তৈরি করা
  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    required bool isGenerating,
    List<Question>? generatedQuiz,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: isGenerating && text.isEmpty
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            if (generatedQuiz != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('Store in Firestore'),
                onPressed: () async {
                  try {
                    final jsonList = generatedQuiz.map((q) => q.toJson()).toList();
                    await FirestoreService().saveGeneratedQuiz('AI Generated', jsonList);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Quiz saved to Firestore!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving quiz: $e')),
                      );
                    }
                  }
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Helper Bot'),
      ),
      body: Consumer<AiProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // চ্যাট মেসেজ লিস্ট
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: provider.messages.length + (provider.isGenerating ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.messages.length) {
                      return _buildMessageBubble(
                        text: provider.currentGeneratingText,
                        isUser: false,
                        isGenerating: true,
                      );
                    }
                    final message = provider.messages[index];
                    return _buildMessageBubble(
                      text: message.text,
                      isUser: message.isUser,
                      isGenerating: false,
                      generatedQuiz: message.generatedQuiz,
                    );
                  },
                ),
              ),

              // কুইজ জেনারেট মোড সুইচার
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    const Text(
                      'Generate Quiz Mode',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Switch(
                      value: provider.isQuizGenerationMode,
                      onChanged: (val) => provider.toggleQuizGenerationMode(val),
                    ),
                  ],
                ),
              ),

              // ইনপুট টেক্সট ফিল্ড ও সেন্ড বাটন
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: provider.isQuizGenerationMode
                              ? 'Topic for quiz...'
                              : 'Type your message...',
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: provider.isGenerating ? null : (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    provider.isGenerating
                        ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                        : Semantics(
                      label: 'Send Message',
                      child: IconButton(
                        tooltip: 'Send Message',
                        icon: const Icon(Icons.send),
                        color: Theme.of(context).primaryColor,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _sendMessage();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}