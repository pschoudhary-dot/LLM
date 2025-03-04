import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';
import 'pocket_llm_service.dart';

class ChatService {
  // Get response from the selected model
  static Future<String> getModelResponse(String userMessage, {
    bool stream = false,
    Function(String)? onToken,
  }) async {
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
        case ModelProvider.pocketLLM:
          return await _getPocketLLMResponse(modelConfig, userMessage, stream, onToken);
        
        case ModelProvider.ollama:
          return await _getOllamaResponse(modelConfig, userMessage, stream, onToken);
        
        case ModelProvider.openAI:
          return await _getOpenAIResponse(modelConfig, userMessage, stream, onToken);
        
        case ModelProvider.anthropic:
          return await _getAnthropicResponse(modelConfig, userMessage, stream, onToken);
        
        case ModelProvider.mistral:
          return await _getMistralResponse(modelConfig, userMessage, stream, onToken);
        
        case ModelProvider.deepseek:
          return await _getDeepseekResponse(modelConfig, userMessage, stream, onToken);
        
        case ModelProvider.lmStudio:
          return await _getLMStudioResponse(modelConfig, userMessage, stream, onToken);
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
    Function(String)? onToken,
  ) async {
    final baseUrl = config.baseUrl;
    final additionalParams = config.additionalParams ?? {};
    final temperature = additionalParams['temperature'] as double? ?? 0.7;
    final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
    
    // First check if the model exists
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tags'));
      if (response.statusCode != 200) {
        throw Exception('Failed to connect to Ollama server');
      }
    } catch (e) {
      debugPrint('Error checking Ollama models: $e');
      return 'Error connecting to Ollama server at ${config.baseUrl}. Please make sure Ollama is running.';
    }
    
    final client = http.Client();
    final completer = Completer<String>();
    final buffer = StringBuffer();
    StreamSubscription? subscription;

    void cleanupAndComplete([String? error]) {
      subscription?.cancel();
      client.close();
      if (error != null) {
        completer.completeError(error);
      } else if (!completer.isCompleted) {
        completer.complete(buffer.toString());
      }
    }

    try {
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Try the v1 API endpoint first (more standard)
      final request = http.Request(
        'POST',
        Uri.parse('${config.baseUrl}/v1/chat/completions'),
      );
      
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': config.id,
        'messages': messages,
        'stream': true,
        'temperature': temperature,
      });

      final response = await client.send(request);
      
      if (response.statusCode == 200) {
        subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.trim().isNotEmpty && line != '[DONE]') {
                try {
                  final data = jsonDecode(line);
                  String? content;
                  
                  // Handle different response formats
                  if (data['choices']?[0]?['delta']?['content'] != null) {
                    content = data['choices'][0]['delta']['content'];
                  } else if (data['message']?['content'] != null) {
                    content = data['message']['content'];
                  }
                  
                  if (content != null && content.isNotEmpty) {
                    buffer.write(content);
                    if (stream && onToken != null) {
                      onToken(content);
                    }
                  }
                } catch (e) {
                  debugPrint('Warning: Error parsing streaming response line: $e');
                  // Don't throw here - continue processing other lines
                }
              }
            },
            onDone: () => cleanupAndComplete(),
            onError: (e) => cleanupAndComplete('Error streaming response: $e'),
            cancelOnError: false  // Don't cancel on parsing errors
          );
      } else {
        cleanupAndComplete('Failed to get response: ${response.statusCode}');
      }

      return await completer.future;
    } catch (e) {
      cleanupAndComplete('Error in Ollama response: $e');
      rethrow;
    }
  }
  
  // Get response from OpenAI compatible API
  static Future<String> _getOpenAIResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to OpenAI compatible API at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Validate the API key
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        return 'API key is required for OpenAI compatible API.';
      }
      
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'messages': messages,
          'stream': stream,
          'temperature': temperature,
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
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to Anthropic API at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Validate the API key
      if (config.apiKey == null || config.apiKey!.isEmpty) {
        return 'API key is required for Anthropic API.';
      }
      
      final Map<String, dynamic> requestBody = {
        'model': config.id,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 1024,
        'temperature': temperature,
      };
      
      // Add system prompt if provided
      if (systemPrompt.isNotEmpty) {
        requestBody['system'] = systemPrompt;
      }
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/v1/messages'),
        headers: {
          'x-api-key': config.apiKey ?? '',
          'Content-Type': 'application/json',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(requestBody),
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
  static Future<String> _getLMStudioResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to LLM Studio at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Implement LLM Studio API call
      final response = await http.post(
        Uri.parse('${config.baseUrl}/api/generate'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'prompt': systemPrompt.isNotEmpty 
              ? '$systemPrompt\n\n$userMessage' 
              : userMessage,
          'max_tokens': 1024,
          'temperature': temperature,
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

  // Get response from PocketLLM
  static Future<String> _getPocketLLMResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      final client = http.Client();
      final completer = Completer<String>();
      final buffer = StringBuffer();
      StreamSubscription? subscription;

      void cleanupAndComplete([String? error]) {
        subscription?.cancel();
        client.close();
        if (error != null) {
          completer.completeError(error);
        } else if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      }

      try {
        final messages = [
          {'role': 'user', 'content': userMessage}
        ];
        
        final temperature = config.additionalParams?['temperature'] ?? 0.7;
        
        final request = http.Request(
          'POST',
          Uri.parse('${config.baseUrl}/chat/completions'),
        );
        
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode({
          'model': config.id,
          'messages': messages,
          'stream': true,
          'temperature': temperature,
        });

        final response = await client.send(request);
        
        if (response.statusCode == 200) {
          subscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.trim().isNotEmpty) {
                  try {
                    // Handle "data: " prefix in SSE
                    String jsonStr = line;
                    if (line.startsWith('data: ')) {
                      jsonStr = line.substring(6);
                    }
                    
                    // Skip "[DONE]" message
                    if (jsonStr.trim() == '[DONE]') {
                      return;
                    }
                    
                    final data = jsonDecode(jsonStr);
                    String? content;
                    
                    // Handle different response formats
                    if (data['message']?['content'] != null) {
                      content = data['message']['content'];
                    } else if (data['choices']?[0]?['delta']?['content'] != null) {
                      content = data['choices'][0]['delta']['content'];
                    } else if (data['choices']?[0]?['message']?['content'] != null) {
                      content = data['choices'][0]['message']['content'];
                    }
                    
                    if (content != null && content.isNotEmpty) {
                      buffer.write(content);
                      if (stream && onToken != null) {
                        onToken(content);
                      }
                    }
                  } catch (e) {
                    debugPrint('Warning: Error parsing streaming response line: $e');
                    // Don't throw here - continue processing other lines
                  }
                }
              },
              onDone: () => cleanupAndComplete(),
              onError: (e) => cleanupAndComplete('Error streaming response: $e'),
              cancelOnError: false  // Don't cancel on parsing errors
            );
        } else {
          cleanupAndComplete('Failed to get response: ${response.statusCode}');
        }

        return await completer.future;
      } catch (e) {
        cleanupAndComplete('Error in PocketLLM response: $e');
        rethrow;
      }
    } catch (e) {
      debugPrint('Error getting response: $e');
      throw Exception('Error connecting to service: $e');
    }
  }

  // Get response from Mistral
  static Future<String> _getMistralResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to Mistral at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'messages': messages,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('Mistral API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting Mistral response: $e');
      return 'Error connecting to Mistral: $e';
    }
  }

  // Get response from DeepSeek
  static Future<String> _getDeepseekResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
    Function(String)? onToken,
  ) async {
    try {
      debugPrint('Connecting to DeepSeek at ${config.baseUrl}');
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
      // Prepare messages with system prompt if provided
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({
          'role': 'system',
          'content': systemPrompt,
        });
      }
      
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
      
      final response = await http.post(
        Uri.parse('${config.baseUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': config.id,
          'messages': messages,
          'temperature': temperature,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint('DeepSeek API error: ${response.statusCode} ${response.body}');
        return 'Failed to get response: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      debugPrint('Error getting DeepSeek response: $e');
      return 'Error connecting to DeepSeek: $e';
    }
  }
} 