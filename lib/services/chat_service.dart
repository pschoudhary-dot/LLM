import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'model_service.dart';
import 'pocket_llm_service.dart';

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
        case ModelProvider.pocketLLM:
          return await _getPocketLLMResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.ollama:
          return await _getOllamaResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.openAI:
          return await _getOpenAIResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.anthropic:
          return await _getAnthropicResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.mistral:
          return await _getMistralResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.deepseek:
          return await _getDeepseekResponse(modelConfig, userMessage, stream);
        
        case ModelProvider.lmStudio:
          return await _getLMStudioResponse(modelConfig, userMessage, stream);
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
      
      // Get additional parameters
      final additionalParams = config.additionalParams ?? {};
      final systemPrompt = additionalParams['systemPrompt'] as String? ?? '';
      final temperature = additionalParams['temperature'] as double? ?? 0.7;
      
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
      
      // Try using the chat completion API with streaming
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

        final client = http.Client();
        final request = http.Request(
          'POST',
          Uri.parse('${config.baseUrl}/api/chat'),
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
          final completer = Completer<String>();
          final buffer = StringBuffer();
          
          response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.trim().isNotEmpty) {
                  try {
                    final data = jsonDecode(line);
                    final content = data['message']?['content'] ?? '';
                    if (content.isNotEmpty) {
                      buffer.write(content);
                    }
                  } catch (e) {
                    debugPrint('Error parsing streaming response: $e');
                  }
                }
              },
              onDone: () {
                completer.complete(buffer.toString());
              },
              onError: (e) {
                completer.completeError('Error streaming response: $e');
              },
              cancelOnError: true,
            );
          
          return await completer.future;
        } else {
          // Try the v1 API endpoint
          final v1Request = http.Request(
            'POST',
            Uri.parse('${config.baseUrl}/v1/chat/completions'),
          );
          
          v1Request.headers['Content-Type'] = 'application/json';
          v1Request.body = jsonEncode({
            'model': config.id,
            'messages': messages,
            'stream': true,
            'temperature': temperature,
          });

          final v1Response = await client.send(v1Request);
          
          if (v1Response.statusCode == 200) {
            final completer = Completer<String>();
            final buffer = StringBuffer();
            
            v1Response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(
                (line) {
                  if (line.trim().isNotEmpty) {
                    try {
                      final data = jsonDecode(line);
                      final content = data['choices']?[0]?['delta']?['content'] ?? '';
                      if (content.isNotEmpty) {
                        buffer.write(content);
                      }
                    } catch (e) {
                      debugPrint('Error parsing streaming response: $e');
                    }
                  }
                },
                onDone: () {
                  completer.complete(buffer.toString());
                },
                onError: (e) {
                  completer.completeError('Error streaming response: $e');
                },
                cancelOnError: true,
              );
            
            return await completer.future;
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
            'prompt': systemPrompt.isNotEmpty 
                ? '$systemPrompt\n\n$userMessage' 
                : userMessage,
            'temperature': temperature,
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
  ) async {
    try {
      debugPrint('Connecting to PocketLLM at ${config.baseUrl}');
      
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
      
      final response = await PocketLLMService.getChatCompletion(
        model: config.id,
        messages: messages,
        temperature: temperature,
      );
      
      if (response['choices'] != null && response['choices'].isNotEmpty) {
        final choice = response['choices'][0];
        if (choice['message'] != null) {
          return choice['message']['content'] ?? '';
        }
      }
      
      return 'No response from PocketLLM';
    } catch (e) {
      debugPrint('Error getting PocketLLM response: $e');
      return 'Error connecting to PocketLLM: $e';
    }
  }

  // Get response from Mistral
  static Future<String> _getMistralResponse(
    ModelConfig config, 
    String userMessage,
    bool stream,
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