class AIModel {
  final String id;
  final String description;  // Add this line
  final String provider;

  AIModel({
    required this.id,
    required this.provider,
    this.description = 'A powerful language model',  // Add default description
  });
}

class ModelsRepository {
  static final List<AIModel> models = [
    AIModel(
      id: 'gpt-3.5-turbo',
      provider: 'OpenAI',
      description: 'Fast and efficient language model optimized for chat',
    ),
    AIModel(
      id: 'gpt-4',
      provider: 'OpenAI',
      description: 'Advanced language model with improved reasoning capabilities',
    ),
    AIModel(
      id: 'claude-3-5-sonnet-20240620',
      provider: 'Anthropic',
      description: 'Anthropic\'s Claude 3.5 Sonnet model (June 2024 version)',
    ),
    AIModel(
      id: 'claude-3-5-sonnet',
      provider: 'Anthropic',
      description: 'Claude 3.5 Sonnet model',
    ),
    AIModel(
      id: 'deepseek-ai/DeepSeek-R1-Distill-Qwen-32B',
      provider: 'DeepSeek',
      description: 'DeepSeek R1 Distill Qwen 32B model',
    ),
    AIModel(
      id: 'deepseek-r1',
      provider: 'DeepSeek',
      description: 'DeepSeek R1 model',
    ),
    AIModel(
      id: 'deepseek-v3',
      provider: 'DeepSeek',
      description: 'DeepSeek V3 model',
    ),
    AIModel(
      id: 'gpt-4o',
      provider: 'OpenAI',
      description: 'GPT-4 Optimized model',
    ),
    AIModel(
      id: 'gpt-4o-2024-05-13',
      provider: 'OpenAI',
      description: 'GPT-4 Optimized (May 2024 version)',
    ),
    AIModel(
      id: 'Meta-Llama-3.3-70B-Instruct-Turbo',
      provider: 'Meta',
      description: 'Llama 3.3 70B Instruct Turbo model',
    ),
  ];
}

class Message {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  // Add fromJson and toJson methods for serialization
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}