import 'package:flutter/material.dart';

class OllamaModel {
  final String name;
  final String description;
  final List<String> parameters;
  final String category;
  final String size;
  final int pulls;
  final int tags;
  final String lastUpdated;
  bool isDownloading = false;
  double downloadProgress = 0.0;
  bool isDownloaded = false;

  OllamaModel({
    required this.name,
    required this.description,
    this.parameters = const [],
    this.category = 'Text',
    this.size = 'Unknown',
    this.pulls = 0,
    this.tags = 0,
    this.lastUpdated = '',
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isDownloaded = false,
  });

  factory OllamaModel.fromJson(Map<String, dynamic> json) {
    List<String> paramList = [];
    if (json['parameters'] != null) {
      paramList = List<String>.from(json['parameters']);
    } else {
      // Extract parameters from tags if available
      if (json['tags'] != null && json['tags'] is List) {
        paramList = List<String>.from(json['tags'].where((tag) => 
          tag is String && (tag.contains('b') || tag == 'tools' || tag == 'vision' || tag == 'embedding')));
      }
    }

    String category = 'Text';
    if (json['category'] != null) {
      category = json['category'];
    } else if (paramList.contains('vision')) {
      category = 'Vision';
    } else if (paramList.contains('embedding')) {
      category = 'Embedding';
    } else if (json['name'].toString().toLowerCase().contains('coder')) {
      category = 'Code';
    }

    return OllamaModel(
      name: json['name'] ?? '',
      description: json['description'] ?? 'No description available',
      parameters: paramList,
      category: category,
      size: json['size'] ?? 'Unknown',
      pulls: json['pulls'] != null ? int.tryParse(json['pulls'].toString()) ?? 0 : 0,
      tags: json['tags'] != null && json['tags'] is List ? json['tags'].length : 0,
      lastUpdated: json['updated'] ?? '',
    );
  }

  // Popular Ollama models with their descriptions and parameters
  static List<OllamaModel> getPopularModels() {
    return [
      OllamaModel(
        name: 'llama3.1',
        description: 'Llama 3.1 is a new state-of-the-art model from Meta available in 8B, 70B and 405B parameter sizes.',
        parameters: ['8b', '70b', '405b', 'tools'],
        category: 'Text',
        pulls: 25200000,
        tags: 93,
        lastUpdated: '2 months ago',
      ),
      OllamaModel(
        name: 'llama3.2',
        description: 'Meta\'s Llama 3.2 goes small with 1B and 3B models.',
        parameters: ['1b', '3b', 'tools'],
        category: 'Text',
        pulls: 9600000,
        tags: 63,
        lastUpdated: '5 months ago',
      ),
      OllamaModel(
        name: 'phi4',
        description: 'Phi-4 is a 14B parameter, state-of-the-art open model from Microsoft.',
        parameters: ['14b'],
        category: 'Text',
        pulls: 798400,
        tags: 5,
        lastUpdated: '7 weeks ago',
      ),
      OllamaModel(
        name: 'mistral',
        description: 'The 7B model released by Mistral AI, updated to version 0.3.',
        parameters: ['7b', 'tools'],
        category: 'Text',
        pulls: 9500000,
        tags: 84,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'qwen2.5',
        description: 'Qwen2.5 models are pretrained on Alibaba\'s latest large-scale dataset, encompassing up to 18 trillion tokens. The model supports up to 128K tokens and has multilingual support.',
        parameters: ['0.5b', '1.5b', '3b', '7b', '14b', '32b', '72b', 'tools'],
        category: 'Text',
        pulls: 4700000,
        tags: 133,
        lastUpdated: '5 months ago',
      ),
      OllamaModel(
        name: 'qwen2.5-coder',
        description: 'The latest series of Code-Specific Qwen models, with significant improvements in code generation, code reasoning, and code fixing.',
        parameters: ['0.5b', '1.5b', '3b', '7b', '14b', '32b', 'tools'],
        category: 'Code',
        pulls: 3800000,
        tags: 196,
        lastUpdated: '3 months ago',
      ),
      OllamaModel(
        name: 'llava',
        description: '🌋 LLaVA is a novel end-to-end trained large multimodal model that combines a vision encoder and Vicuna for general-purpose visual and language understanding. Updated to version 1.6.',
        parameters: ['7b', '13b', '34b'],
        category: 'Vision',
        pulls: 3600000,
        tags: 98,
        lastUpdated: '13 months ago',
      ),
      OllamaModel(
        name: 'codellama',
        description: 'A large language model that can use text prompts to generate and discuss code.',
        parameters: ['7b', '13b', '34b', '70b'],
        category: 'Code',
        pulls: 1800000,
        tags: 199,
        lastUpdated: '7 months ago',
      ),
      OllamaModel(
        name: 'llama3.2-vision',
        description: 'Llama 3.2 Vision is a collection of instruction-tuned image reasoning generative models in 11B and 90B sizes.',
        parameters: ['11b', '90b'],
        category: 'Vision',
        pulls: 1400000,
        tags: 9,
        lastUpdated: '3 months ago',
      ),
      OllamaModel(
        name: 'mxbai-embed-large',
        description: 'State-of-the-art large embedding model from mixedbread.ai',
        parameters: ['335m'],
        category: 'Embedding',
        pulls: 1600000,
        tags: 4,
        lastUpdated: '9 months ago',
      ),
    ];
  }

  // Get icon based on category
  IconData getCategoryIcon() {
    switch (category.toLowerCase()) {
      case 'vision':
        return Icons.image;
      case 'audio':
        return Icons.mic;
      case 'embedding':
        return Icons.data_array;
      case 'code':
        return Icons.code;
      case 'text':
      default:
        return Icons.text_fields;
    }
  }

  // Get color based on category
  MaterialColor getCategoryColor() {
    switch (category.toLowerCase()) {
      case 'vision':
        return Colors.blue;
      case 'audio':
        return Colors.orange;
      case 'embedding':
        return Colors.teal;
      case 'code':
        return Colors.indigo;
      case 'text':
      default:
        return Colors.purple;
    }
  }
}
