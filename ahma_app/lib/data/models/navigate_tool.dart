import 'dart:convert';
import 'package:flutter/services.dart';
import 'client_tool_result.dart';

/// Navigate tool implementation for client-side stage navigation
class NavigateTool {
  static const String navigationToolName = 'navigate';
  static Map<String, dynamic>? _staticResponses;

  /// Map agent's stage names to internal stage names
  static String _mapStageName(String agentStageName) {
    switch (agentStageName) {
      case 'RESOURCES':
        return 'AHMA_RESOURCES';
      case 'SCHEDULING':
        return 'SCHEDULE';
      case 'GREETING':
        return 'GREETING';
      case 'RESCHEDULE':
        return 'RESCHEDULE';
      case 'AHMA_GREETING':
        return 'AHMA_GREETING';
      default:
        return agentStageName;
    }
  }

  static String _normalizeToolName(dynamic tool) {
    final toolName = tool is Map<String, dynamic>
        ? tool['toolName'] ?? tool['toolId'] ?? tool['name']
        : tool;

    return toolName == 'navigateStage'
        ? navigationToolName
        : toolName.toString();
  }

  /// Load static responses from pure_client_tool.json
  static Future<void> _loadStaticResponses() async {
    if (_staticResponses != null && _staticResponses!.isNotEmpty) return;

    try {
      final jsonString = await rootBundle.loadString(
        'lib/data/models/pure_client_tool.json',
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      _staticResponses =
          data['x-temporaryTool']['staticResponses'] as Map<String, dynamic>;
      print(
        '[NavigateTool] ✅ Loaded ${_staticResponses!.length} static stage responses',
      );
    } catch (e) {
      print('[NavigateTool] ❌ Error loading static responses: $e');
      _staticResponses = null;
    }
  }

  static List<String> get _defaultAllowedStages => const [
    'GREETING',
    'SCHEDULE',
    'RESCHEDULE',
    'AHMA_GREETING',
    'AHMA_RESOURCES',
  ];

  /// Handle navigate tool calls from Ultravox agent
  static Future<ClientToolResult> handleNavigate(
    Map<String, dynamic> parameters,
  ) async {
    try {
      await _loadStaticResponses();

      final stageName = parameters['stageName'] as String?;

      if (stageName == null || stageName.isEmpty) {
        return ClientToolResult(
          result: 'Error: stageName parameter is required',
          responseType: 'error',
        );
      }

      // Map agent's stage names to internal stage names
      final mappedStageName = _mapStageName(stageName.trim().toUpperCase());

      // Get static response for this stage
      final stageResponse = _staticResponses?[mappedStageName];

      if (stageResponse == null) {
        final allowedStages = (_staticResponses?.keys.isNotEmpty ?? false)
            ? _staticResponses!.keys.toList()
            : _defaultAllowedStages;
        return ClientToolResult(
          result:
              'Error: Invalid stage "$stageName". Available stages: ${allowedStages.join(', ')}',
          responseType: 'error',
        );
      }

      final systemPrompt = (stageResponse['systemPrompt'] as String).replaceAll(
        '{date}',
        DateTime.now().toIso8601String().split('T').first,
      );

      // Convert selectedTools to proper Ultravox format.
      // Stale configs may still say navigateStage; Ultravox is configured for navigate.
      final selectedTools = stageResponse['selectedTools'] as List<dynamic>;
      final formattedTools = selectedTools
          .map((tool) => {'toolName': _normalizeToolName(tool)})
          .toList();

      // Create the stage response as a JSON string.
      // Only include valid stage properties: systemPrompt, selectedTools.
      // toolResultText is not a valid stage property and causes Bad Request.
      final stageResponseMap = {
        'systemPrompt': systemPrompt,
        'selectedTools': formattedTools,
      };

      // Convert to JSON string like the Python client SDK example
      final stageResponseJson = jsonEncode(stageResponseMap);

      print(
        '[NavigateTool] 📍 Returning new-stage response for stage: $stageName',
      );

      return ClientToolResult(
        result: stageResponseJson, // Return JSON string, not Map
        responseType: 'new-stage',
      );
    } catch (e) {
      return ClientToolResult(
        result: 'Error processing navigate tool: $e',
        responseType: 'error',
      );
    }
  }
}
