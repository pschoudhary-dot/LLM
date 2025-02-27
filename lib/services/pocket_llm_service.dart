import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';

class PocketLLMService {
  static const String baseUrl = 'https://api.sree.shop/v1';
  static const String apiKey = 'ddc-m4qlvrgpt1W1E4ZXc4bvm5T5Z6CRFLeXRCx9AbRuQOcGpFFrX2';

  // Get available models
  static Future<List<Map<String, dynamic>>> getAvailableModels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching PocketLLM models: $e');
      throw Exception('Error fetching models: $e');
    }
  }

  // Get chat completion
  static Future<Map<String, dynamic>> getChatCompletion({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get completion: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting chat completion: $e');
      throw Exception('Error getting completion: $e');
    }
  }

  // Create default model config
  static ModelConfig createDefaultConfig() {
    return ModelConfig(
      id: 'gpt-4o',
      name: 'PocketLLM GPT-4',
      provider: ModelProvider.pocketLLM,
      baseUrl: baseUrl,
      apiKey: apiKey,
      additionalParams: {
        'temperature': 0.7,
        'systemPrompt': 'You are a helpful AI assistant.',
      },
    );
  }

  // Test connection
  static Future<bool> testConnection(ModelConfig config) async {
    try {
      final response = await http.get(
        Uri.parse('${config.baseUrl}/models'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing PocketLLM connection: $e');
      return false;
    }
  }
} 