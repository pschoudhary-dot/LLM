import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ollama_dart/ollama_dart.dart';

// Enum for model providers
enum ModelProvider {
  ollama,
  openAI,
  anthropic,
  llmStudio,
}

// Extension to get display name for providers
extension ModelProviderExtension on ModelProvider {
  String get displayName {
    switch (this) {
      case ModelProvider.ollama:
        return 'Ollama';
      case ModelProvider.openAI:
        return 'OpenAI Compatible';
      case ModelProvider.anthropic:
        return 'Anthropic';
      case ModelProvider.llmStudio:
        return 'LLM Studio';
    }
  }
}

// Model configuration class
class ModelConfig {
  final String id;
  final String name;
  final ModelProvider provider;
  final String baseUrl;
  final String? apiKey;
  final Map<String, dynamic>? additionalParams;

  ModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.baseUrl,
    this.apiKey,
    this.additionalParams,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider': provider.index,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'additionalParams': additionalParams,
    };
  }

  // Create from JSON for retrieval
  factory ModelConfig.fromJson(Map<String, dynamic> json) {
    return ModelConfig(
      id: json['id'],
      name: json['name'],
      provider: ModelProvider.values[json['provider']],
      baseUrl: json['baseUrl'],
      apiKey: json['apiKey'],
      additionalParams: json['additionalParams'],
    );
  }
}

// Service to manage model configurations
class ModelService {
  static const String _storageKey = 'model_configs';
  static const String _selectedModelKey = 'selected_model';
  
  // Default Ollama URL
  static const String defaultOllamaUrl = 'http://localhost:11434';
  
  // Get all saved model configurations
  static Future<List<ModelConfig>> getModelConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configsJson = prefs.getString(_storageKey);
    
    if (configsJson == null) {
      return [];
    }
    
    final List<dynamic> configsList = jsonDecode(configsJson);
    return configsList.map((json) => ModelConfig.fromJson(json)).toList();
  }
  
  // Save a new model configuration
  static Future<void> saveModelConfig(ModelConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ModelConfig> configs = await getModelConfigs();
    
    // Check if config with same ID already exists
    final existingIndex = configs.indexWhere((c) => c.id == config.id);
    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }
    
    final String configsJson = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, configsJson);
  }
  
  // Delete a model configuration
  static Future<void> deleteModelConfig(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<ModelConfig> configs = await getModelConfigs();
    
    configs.removeWhere((c) => c.id == id);
    
    final String configsJson = jsonEncode(configs.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, configsJson);
  }
  
  // Set the selected model
  static Future<void> setSelectedModel(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedModelKey, id);
  }
  
  // Clear the selected model (when no models are available)
  static Future<void> clearSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedModelKey);
  }
  
  // Get the selected model
  static Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedModelKey);
  }
  
  // Get available models from Ollama
  static Future<List<String>> getOllamaModels(String baseUrl) async {
    try {
      debugPrint('Fetching Ollama models from $baseUrl');
      // Use direct HTTP request instead of the client's listModels method
      final response = await http.get(
        Uri.parse('$baseUrl/api/tags'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['models'] as List<dynamic>?) ?? [];
        return models.map((model) => model['name'].toString()).toList();
      } else {
        // Try the v1 API endpoint if the api/tags endpoint fails
        final v1Response = await http.get(
          Uri.parse('$baseUrl/v1/models'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        if (v1Response.statusCode == 200) {
          final data = jsonDecode(v1Response.body);
          final models = (data['models'] as List<dynamic>?) ?? [];
          return models.map((model) => model['name'].toString()).toList();
        }
        
        debugPrint('Failed to fetch Ollama models: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching Ollama models: $e');
      return [];
    }
  }
  
  // Test connection to model provider
  static Future<bool> testConnection(ModelConfig config) async {
    try {
      switch (config.provider) {
        case ModelProvider.ollama:
          // Use direct HTTP request instead of the client
          final response = await http.get(
            Uri.parse('${config.baseUrl}/api/tags'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            return true;
          }
          
          // Try the v1 API endpoint if the api/tags endpoint fails
          final v1Response = await http.get(
            Uri.parse('${config.baseUrl}/v1/models'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          return v1Response.statusCode == 200;
        
        case ModelProvider.openAI:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/models'),
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
            },
          );
          return response.statusCode == 200;
        
        case ModelProvider.anthropic:
          final response = await http.get(
            Uri.parse('${config.baseUrl}/v1/models'),
            headers: {
              'x-api-key': config.apiKey ?? '',
              'Content-Type': 'application/json',
            },
          );
          return response.statusCode == 200;
        
        case ModelProvider.llmStudio:
          // Implement LLM Studio connection test
          return true;
      }
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }
} 