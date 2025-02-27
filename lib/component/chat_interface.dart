import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clipboard/clipboard.dart';
import 'models.dart';
import 'tavily_service.dart';
import 'chat_history_manager.dart'; // Import the new chat history manager
import '../services/chat_service.dart';
import '../services/model_service.dart' as service;
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
  service.ModelConfig? _selectedModelConfig;
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
      final selectedId = await service.ModelService.getSelectedModel();
      if (selectedId != null) {
        final configs = await service.ModelService.getModelConfigs();
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
    
    // Create a placeholder message for the AI response
    final aiMessage = Message(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isThinking: true,
    );
    
    setState(() {
      _messages.add(aiMessage);
    });
    _scrollToBottom();
    
    try {
      final aiResponse = await _getAIResponse(userMessage);
      String cleanedResponse = _cleanUpResponse(aiResponse);
      
      setState(() {
        aiMessage.content = cleanedResponse;
        aiMessage.isThinking = false;
      });
      
      if (_isOnline) {
        final tavilyResults = await _performWebSearch(userMessage);
        setState(() {
          aiMessage.content = '$cleanedResponse\n\n**Web Search Results:**\n$tavilyResults';
        });
      }
    } catch (e) {
      setState(() {
        aiMessage.content = 'Error: $e';
        aiMessage.isThinking = false;
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
                    padding: const EdgeInsets.only(bottom: 20),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
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
              const SizedBox(height: 12),
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildAttachmentButton(),
            SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
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
                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                          ),
                        ),
                      )
                    else ...[
                      IconButton(
                        icon: Icon(Icons.mic, color: Colors.grey[600]),
                        onPressed: () {
                          // Handle voice input
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Color(0xFF8B5CF6)),
                        onPressed: () => _sendMessage(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.attach_file, color: Colors.grey[700]),
      offset: Offset(0, -200), // Show menu above the button
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'camera',
          child: ListTile(
            leading: Icon(Icons.camera_alt_outlined, color: Color(0xFF8B5CF6)),
            title: Text('Camera'),
          ),
        ),
        PopupMenuItem(
          value: 'gallery',
          child: ListTile(
            leading: Icon(Icons.image_outlined, color: Color(0xFF8B5CF6)),
            title: Text('Gallery'),
          ),
        ),
        PopupMenuItem(
          value: 'files',
          child: ListTile(
            leading: Icon(Icons.folder_outlined, color: Color(0xFF8B5CF6)),
            title: Text('Files'),
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'camera':
            // Handle camera
            break;
          case 'gallery':
            // Handle gallery
            break;
          case 'files':
            // Handle files
            break;
        }
      },
    );
  }

  void _showMessageOptions(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMessageOption(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
                FlutterClipboard.copy(message.content);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (message.isUser) ...[
              _buildMessageOption(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  _messageController.text = message.content;
                  // Remove the old message
                  setState(() {
                    _messages.remove(message);
                  });
                },
              ),
            ] else ...[
              _buildMessageOption(
                icon: Icons.refresh,
                label: 'Regenerate',
                onTap: () {
                  Navigator.pop(context);
                  // Handle regeneration
                },
              ),
              _buildMessageOption(
                icon: Icons.thumb_down,
                label: 'Bad Response',
                onTap: () {
                  Navigator.pop(context);
                  // Handle feedback
                },
              ),
              _buildMessageOption(
                icon: Icons.volume_up,
                label: 'Read Aloud',
                onTap: () {
                  Navigator.pop(context);
                  // Handle text-to-speech
                },
              ),
            ],
            _buildMessageOption(
              icon: Icons.auto_awesome,
              label: 'Model',
              trailing: Text(
                _selectedModelConfig?.name ?? 'Select Model',
                style: TextStyle(color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.pop(context);
                _showModelSelectionSheet();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildMessageBubble(Message message) {
    final timestamp = message.timestamp;
    final formattedTime = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}";
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context, message),
      child: Column(
        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: message.isUser ? Color(0xFF8B5CF6) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: message.isUser ? null : Border.all(color: Colors.grey[200]!),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isThinking)
                          _buildThinkingIndicator()
                        else
                          Text(
                            message.content,
                            style: TextStyle(
                              color: message.isUser ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (message.isUser)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 16,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: message.isUser ? 0 : 48,
              right: message.isUser ? 48 : 0,
              bottom: 8,
              top: 0,
            ),
            child: Text(
              formattedTime,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Text(
          'Thinking...',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Future<void> _showModelSelectionSheet() async {
    final configs = await service.ModelService.getModelConfigs();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Model',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: configs.length,
                itemBuilder: (context, index) {
                  final config = configs[index];
                  final isSelected = config.id == _selectedModelId;
                  
                  return InkWell(
                    onTap: () async {
                      await service.ModelService.setSelectedModel(config.id);
                      setState(() {
                        _selectedModelId = config.id;
                        _selectedModelConfig = config;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFFF3F4F6) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getProviderIcon(),
                              color: Color(0xFF8B5CF6),
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  config.provider.toString().split('.').last,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method to get provider icon
  IconData _getProviderIcon() {
    if (_selectedModelConfig == null) return Icons.psychology;
    
    switch (_selectedModelConfig!.provider) {
      case service.ModelProvider.ollama:
        return Icons.terminal;
      case service.ModelProvider.openAI:
        return Icons.auto_awesome;
      case service.ModelProvider.anthropic:
        return Icons.psychology;
      case service.ModelProvider.lmStudio:
        return Icons.science;
      default:
        return Icons.psychology;
    }
  }
}