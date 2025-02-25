import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'models.dart';
import 'tavily_service.dart';
import 'chat_history_manager.dart'; // Import the new chat history manager

class ChatInterface extends StatefulWidget {
  @override
  _ChatInterfaceState createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late String _selectedModel;
  final String apiKey = 'ddc-m4qlvrgpt1W1E4ZXc4bvm5T5Z6CRFLeXRCx9AbRuQOcGpFFrX2';
  final String apiUrl = 'https://api.sree.shop/v1/chat/completions';
  final TavilyService _tavilyService = TavilyService();
  bool _isOnline = false;
  final ChatHistoryManager _chatHistoryManager = ChatHistoryManager();

  // Suggested messages (dynamic)
  List<String> _suggestedMessages = [];

  @override
  void initState() {
    super.initState();
    _selectedModel = ModelsRepository.models.first.id;
    _loadChatHistory();
    _generateSuggestedQuestions(); // Generate dynamic questions on startup
  }

  Future<void> _generateSuggestedQuestions() async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _selectedModel,
          'messages': [
            {
              'role': 'user',
              'content':
                  'Generate 3 interesting and engaging questions with emojis for a chatbot conversation.',
            }
          ],
          'temperature': 0.8,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        setState(() {
          _suggestedMessages = aiResponse.split('\n').map((q) => q.trim()).toList();
        });
      } else {
        throw Exception('Failed to generate suggested questions');
      }
    } catch (e) {
      setState(() {
        _suggestedMessages = [
          "🤔 What's the meaning of life?",
          "🌍 How can we protect the environment?",
          "🤖 What are the latest AI trends?"
        ];
      });
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
    try {
      final aiResponse = await _getAIResponse(userMessage);
      String cleanedResponse = _cleanUpResponse(aiResponse);
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
      setState(() {
        _messages.add(Message(
          content: 'Error: Something went wrong',
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
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _selectedModel,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get AI response');
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

  Widget _buildModelSelector() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Theme(
          data: ThemeData(canvasColor: Colors.white),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedModel,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF8B5CF6)),
              isExpanded: true,
              items: ModelsRepository.models.map((model) {
                return DropdownMenuItem<String>(
                  value: model.id,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      model.id,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedModel = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebIcon() {
    return InkWell(
      onTap: () {
        setState(() {
          _isOnline = !_isOnline;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Icon(
              Icons.public,
              color: _isOnline ? Colors.green : Colors.grey,
              size: 30,
            ),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: _isOnline ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedMessages() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Start a conversation with one of these:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedMessages.map((message) {
              return ElevatedButton(
                onPressed: () {
                  _messageController.text = message;
                  _sendMessage();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
              'assets/images/logo.png', // Make sure to add this image
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
              height: 56, // Increased height
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.image_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.folder_outlined),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (value) => _sendMessage(),
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
                  child: MarkdownBody(
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
                    if (!message.isUser) ...[
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
}