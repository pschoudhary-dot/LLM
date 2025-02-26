import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ollama_dart/ollama_dart.dart';
import 'model_service.dart';

class ChatService {
  // Get response from the selected model
  static Future<String> getModelResponse(String userMessage, {bool stream = false}) async {
    try {
      // Get the selected model configuration
      final selectedModelId = await ModelService.getSelectedModel();
      if (selectedModelId == null) {
        return 'No model selected. Please configure a model in Settings.';
      }
      
      final modelConfigs = await ModelService.getModelConfigs();
      final modelConfig = modelConfigs.firstWhere(
        (config) => config.id == selectedModelId,
        orElse: () => throw Exception('Selected model not found'),
      );
      
      // Call the appropriate provider based on the model configuration
      switch (modelConfig.provider) {
        case ModelProvider.ollama:
          return await _getOllamaResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.openAI:
          return await _getOpenAIResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.anthropic:
          return await _getAnthropicResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.llmStudio:
          return await _getLLMStudioResponse(modelConfig, userMessage, stream);
      }
    } catch (e) {
      debugPrint('Error getting model response: $e');
      return 'Error: $e';
    }
  }
  
  // Get response from Ollama
  static Future<String> _getOllamaResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
  ) async {
    try {
      debugPrint('Connecting to Ollama at ${config.baseUrl}');
      
      // First check if the model exists
      try {
        final modelResponse = await http.get(
          Uri.parse('${config.baseUrl}/api/tags'),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        
        bool modelExists = false;
        
        if (modelResponse.statusCode == 200) {
          final data = jsonDecode(modelResponse.body);
          final models = (data['models'] as List<dynamic>?) ?? [];
          modelExists = models.any((model) => model['name'] == config.id);
        } else {
          // Try the v1 API endpoint
          final v1Response = await http.get(
            Uri.parse('${config.baseUrl}/v1/models'),
            headers: {
              'Content-Type': 'application/json',
            },
          );
          
          if (v1Response.statusCode == 200) {
            final data = jsonDecode(v1Response.body);
            final models = (data['models'] as List<dynamic>?) ?? [];
            modelExists = models.any((model) => model['id'] == config.id);
          }
        }
        
        if (!modelExists) {
          return 'Model "${config.id}" not found in Ollama. Please make sure it is installed.';
        }
      } catch (e) {
        debugPrint('Error checking Ollama models: $e');
        return 'Error connecting to Ollama server at ${config.baseUrl}. Please make sure Ollama is running.';
      }
      
      // Try using the chat completion API
      try {
        final response = await http.post(
          Uri.parse('${config.baseUrl}/api/chat'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.id,
            'messages': [
              {
                'role': 'user',
                'content': userMessage,
              },
            ],
            'stream': stream,
          }),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['message']['content'] ?? '';
        } else {
          // Try the v1 API endpoint
          final v1Response = await http.post(
            Uri.parse('${config.baseUrl}/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': config.id,
              'messages': [
                {
                  'role': 'user',
                  'content': userMessage,
                },
              ],
              'stream': stream,
            }),
          );
          
          if (v1Response.statusCode == 200) {
            final data = jsonDecode(v1Response.body);
            return data['choices'][0]['message']['content'] ?? '';
          }
        }
        
        // Fall back to the generate API if chat completion fails
        final generateResponse = await http.post(
          Uri.parse('${config.baseUrl}/api/generate'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.id,
            'prompt': userMessage,
          }),
        );
        
        if (generateResponse.statusCode == 200) {
          final data = jsonDecode(generateResponse.body);
          return data['response'] ?? '';
        } else {
          return 'Failed to get response from Ollama: ${generateResponse.statusCode}';
        }
      } catch (e) {
        debugPrint('Error getting Ollama response: $e');
        return 'Error connecting to Ollama: $e';
      }
    } catch (e) {
      debugPrint('Error getting Ollama response: $e');
      return 'Error connecting to Ollama: $e';
    }
  }
  
  // Get response from OpenAI compatible API
  static Future<String> _getOpenAIResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
  ) async {
    try {
      debugPrint('Connecting to OpenAI compatible API at ${config.baseUrl}');
      
      // Validate the API key
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        return 'API key is required for OpenAI compatible API.';
      }
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
          'stream': stream,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('OpenAI API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting OpenAI response: $e');
      return 'Error connecting to OpenAI: $e';
    }
  }
  
  // Get response from Anthropic
  static Future<String> _getAnthropicResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
  ) async {
    try {
      debugPrint('Connecting to Anthropic API at ${config.baseUrl}');
      
      // Validate the API key
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        return 'API key is required for Anthropic API.';
      }
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/v1/messages'),
        headers: {
          'x-api-key': config.apiKey ?? '',
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': config.id,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
          'max_tokens': 1024,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        debugPrint('Anthropic API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting Anthropic response: $e');
      return 'Error connecting to Anthropic: $e';
    }
  }
  
  // Get response from LLM Studio
  static Future<String> _getLLMStudioResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
  ) async {
    try {
      debugPrint('Connecting to LLM Studio at ${config.baseUrl}');
      
      // Implement LLM Studio API call
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'prompt': userMessage,
          'max_tokens': 1024,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response from LLM Studio';
      } else {
        debugPrint('LLM Studio API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting LLM Studio response: $e');
      return 'Error connecting to LLM Studio: $e';
    }
  }
} 