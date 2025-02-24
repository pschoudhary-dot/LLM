class AIModel {
  final String id;
  final String description;
  final String provider;
  final List<String> parameterVariants;
  final int downloads;
  final int comments;
  final DateTime releaseDate;
  final String? downloadUrl;
  final String? providerUrl;
  final List<String> tools;

  AIModel({
    required this.id,
    required this.provider,
    required this.description,
    required this.parameterVariants,
    required this.releaseDate,
    this.downloads = 0,
    this.comments = 0,
    this.downloadUrl,
    this.providerUrl,
    this.tools = const [],
  });
}

class ModelsRepository {
  static final List<AIModel> models = [
    AIModel(
      id: 'deepseek-r1',
      provider: 'DeepSeek',
      description: 'DeepSeek\'s first-generation of reasoning models with comparable performance to OpenAI-r1, including six dense models distilled from DeepSeek-R1 based on Llama and Qwen.',
      parameterVariants: ['1.5b', '7b', '8b', '14b', '32b', '67b'],
      downloads: 20000000,
      comments: 29,
      releaseDate: DateTime.now().subtract(Duration(days: 14)),
    ),
    AIModel(
      id: 'llama3.3',
      provider: 'Meta',
      description: 'New state of the art 70B model. Llama 3.3 70B offers similar performance compared to the Llama 3.1 405B model.',
      parameterVariants: ['70b'],
      downloads: 1400000,
      comments: 14,
      releaseDate: DateTime.now().subtract(Duration(days: 60)),
      tools: ['tools'],
    ),
    AIModel(
      id: 'phi4',
      provider: 'Microsoft',
      description: 'Phi-4 is a 14B parameter, state-of-the-art open model from Microsoft.',
      parameterVariants: ['14b'],
      downloads: 702800,
      comments: 5,
      releaseDate: DateTime.now().subtract(Duration(days: 42)),
    ),
    AIModel(
      id: 'llama3.2',
      provider: 'Meta',
      description: 'Meta\'s Llama 3.2 goes small with 1B and 3B models.',
      parameterVariants: ['1b', '3b'],
      downloads: 9300000,
      comments: 63,
      releaseDate: DateTime.now().subtract(Duration(days: 150)),
      tools: ['tools'],
    ),
    AIModel(
      id: 'llama3.1',
      provider: 'Meta',
      description: 'Llama 3.1 is a new state-of-the-art model from Meta available in 8B, 70B and 405B parameter sizes.',
      parameterVariants: ['8b', '70b', '405b'],
      downloads: 24800000,
      comments: 93,
      releaseDate: DateTime.now().subtract(Duration(days: 60)),
      tools: ['tools'],
    ),
  ];

  static List<AIModel> getAvailableModels() {
    final sortedModels = List<AIModel>.from(models);
    sortedModels.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return sortedModels;
  }
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