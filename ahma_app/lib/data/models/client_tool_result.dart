/// Client tool result for Ultravox navigate tool
class ClientToolResult {
  final String result;
  final String responseType;

  const ClientToolResult({required this.result, required this.responseType});

  @override
  String toString() {
    return 'ClientToolResult(result: $result, responseType: $responseType)';
  }
}
