import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'models.dart';
import 'tavily_service.dart';
import 'chat_history_manager.dart'; // Import the new chat history manager
import '../services/chat_service.dart';
import '../services/model_service.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ChatInterface extends StatefulWidget {
  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  // Add these new state variables at the top of the class
  bool _showAttachmentOptions = false;
  double _inputHeight = 56.0;
  final double _maxInputHeight = 120.0;  // Maximum height for input area
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  String? _selectedModelId;
  ModelConfig? _selectedModelConfig;
  final String apiKey = 'ddc-m4qlvrgpt1W1E4ZXc4bvm5T5Z6CRFLeXRCx9AbRuQOcGpFFrX2';
  final String apiUrl = 'https://api.sree.shop/v1/chat/completions';
  final TavilyService _tavilyService = TavilyService();
  bool _isOnline = false;
  final ChatHistoryManager _chatHistoryManager = ChatHistoryManager();

  // Suggested messages (dynamic)
  List<String> _suggestedMessages = [
    "🤔 What's the meaning of life?",
    "🌍 How can we protect the environment?",
    "🤖 What are the latest AI trends?"
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
    _loadChatHistory();
  }

  Future<void> _loadSelectedModel() async {
    try {
      final selectedId = await ModelService.getSelectedModel();
      if (selectedId != null) {
        final configs = await ModelService.getModelConfigs();
        final config = configs.firstWhere(
          (config) => config.id == selectedId,
          orElse: () => throw Exception('Selected model not found'),
        );
        
        setState(() {
          _selectedModelId = selectedId;
          _selectedModelConfig = config;
        });
      }
    } catch (e) {
      print('Error loading selected model: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    final savedMessages = await _chatHistoryManager.loadChatHistory();
    setState(() {
      _messages.addAll(savedMessages);
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    // Check if a model is selected
    if (_selectedModelId == null || _selectedModelConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a model in the app bar first'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ),
      );
      return;
    }
    
    final userMessage = _messageController.text;
    final newMessage = Message(
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(newMessage);
      _isLoading = true;
    });
    
    _messageController.clear();
    _saveChatHistory();
    
    // Add a thinking message for Ollama models
    Message? thinkingMessage;
    if (_selectedModelConfig!.provider == ModelProvider.ollama) {
      thinkingMessage = Message(
        content: 'Thinking...',
        isUser: false,
        timestamp: DateTime.now(),
        isThinking: true,
      );
      
      setState(() {
        _messages.add(thinkingMessage!);
      });
      _scrollToBottom();
    }
    
    try {
      final aiResponse = await _getAIResponse(userMessage);
      String cleanedResponse = _cleanUpResponse(aiResponse);
      
      // Remove the thinking message if it exists
      if (thinkingMessage != null) {
        setState(() {
          _messages.remove(thinkingMessage);
        });
      }
      
      if (_isOnline) {
        final tavilyResults = await _performWebSearch(userMessage);
        setState(() {
          _messages.add(Message(
            content: '$cleanedResponse\n\n**Web Search Results:**\n$tavilyResults',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(Message(
            content: cleanedResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      // Remove the thinking message if it exists
      if (thinkingMessage != null) {
        setState(() {
          _messages.remove(thinkingMessage);
        });
      }
      
      setState(() {
        _messages.add(Message(
          content: 'Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  String _cleanUpResponse(String response) {
    return response.replaceAll(RegExp(r"In\s*\$\~{3}\$.*?\$\~{3}\$"), '').trim();
  }

  Future<void> _saveChatHistory() async {
    await _chatHistoryManager.saveChatHistory(_messages);
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      // Use the ChatService to get a response from the selected model
      return await ChatService.getModelResponse(userMessage);
    } catch (e) {
      print('Error getting AI response: $e');
      throw Exception('Failed to get AI response: $e');
    }
  }

  Future<String> _performWebSearch(String query) async {
    try {
      final result = await _tavilyService.search(query);
      final answer = result['answer'] ?? 'No answer found.';
      final results = (result['results'] as List)
          .map((item) => '- ${item['title']} (${item['url']})')
          .join('\n');
      return '$answer\n\n$results';
    } catch (e) {
      return 'Error fetching web search results: $e';
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Plus',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.add, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/icons/icon.jpg', // Make sure to add this image
              width: 48,
              height: 48,
              color: Colors.grey[300],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              _buildSuggestionCard(
                "Create a cartoon",
                "illustration of my pet",
                Icons.brush_outlined,
              ),
              SizedBox(height: 12),
              _buildSuggestionCard(
                "What can PocketLLM do",
                "and how to get started",
                Icons.help_outline,
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildSuggestionCard(String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        _messageController.text = "$title: $subtitle";
        _sendMessage();
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _maxInputHeight,
                minHeight: 56,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment section
                  if (_showAttachmentOptions) ...[
                    IconButton(
                      icon: Icon(Icons.camera_alt_outlined),
                      onPressed: () {
                        // Handle camera
                        setState(() => _showAttachmentOptions = false);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.image_outlined),
                      onPressed: () {
                        // Handle image
                        setState(() => _showAttachmentOptions = false);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.folder_outlined),
                      onPressed: () {
                        // Handle file
                        setState(() => _showAttachmentOptions = false);
                      },
                    ),
                  ] else
                    IconButton(
                      icon: Icon(Icons.attach_file),
                      onPressed: () {
                        setState(() => _showAttachmentOptions = true);
                      },
                    ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onSubmitted: (value) => _sendMessage(),
                      onChanged: (value) {
                        // Calculate new height based on content
                        final numLines = '\n'.allMatches(value).length + 1;
                        final newHeight = (numLines * 20.0).clamp(56.0, _maxInputHeight);
                        if (newHeight != _inputHeight) {
                          setState(() => _inputHeight = newHeight);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.public,
                      color: _isOnline ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _isOnline = !_isOnline;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            backgroundColor: Color(0xFF8B5CF6),
            onPressed: _sendMessage,
            child: Icon(
              _isLoading ? Icons.auto_awesome : Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFF8B5CF6),
                radius: 16,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isUser)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      'PocketLLM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser ? const Color(0xFF8B5CF6) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: message.isThinking
                      ? _buildThinkingIndicator()
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: TextStyle(
                              color: message.isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.grey[200],
                              color: Colors.black87,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    if (!message.isUser && !message.isThinking) ...[
                      const SizedBox(width: 8),
                      _buildCopyButton(message.content),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (message.isUser)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFF4CAF50),
                radius: 16,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCopyButton(String content) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          FlutterClipboard.copy(content).then((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Copied to clipboard!'),
                  ],
                ),
                backgroundColor: const Color(0xFF8B5CF6),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF8B5CF6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.copy,
                size: 16,
                color: Color(0xFF8B5CF6),
              ),
              SizedBox(width: 4),
              Text(
                'Copy',
                style: TextStyle(
                  color: Color(0xFF8B5CF6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Thinking...',
              textStyle: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              ),
              speed: Duration(milliseconds: 100),
            ),
          ],
          repeatForever: true,
          displayFullTextOnTap: false,
        ),
      ],
    );
  }
}