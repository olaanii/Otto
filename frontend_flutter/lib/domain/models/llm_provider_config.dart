/// Configuration options for LLM providers used to intelligently slice diffs
/// and synthesize conventional commit messages.
class LlmProviderConfig {
  final String id;
  final String name;
  final String provider; // 'anthropic', 'openai', 'google', 'openrouter', 'ollama'
  final String modelId;
  final bool isConfigured;
  final double temperature;
  final int maxTokens;
  final bool isDefault;

  const LlmProviderConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.modelId,
    this.isConfigured = false,
    this.temperature = 0.2,
    this.maxTokens = 2048,
    this.isDefault = false,
  });

  LlmProviderConfig copyWith({
    String? id,
    String? name,
    String? provider,
    String? modelId,
    bool? isConfigured,
    double? temperature,
    int? maxTokens,
    bool? isDefault,
  }) {
    return LlmProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      modelId: modelId ?? this.modelId,
      isConfigured: isConfigured ?? this.isConfigured,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        'modelId': modelId,
        'isConfigured': isConfigured,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'isDefault': isDefault,
      };

  factory LlmProviderConfig.fromJson(Map<String, dynamic> json) => LlmProviderConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        provider: json['provider'] as String,
        modelId: json['modelId'] as String,
        isConfigured: json['isConfigured'] as bool? ?? false,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.2,
        maxTokens: json['maxTokens'] as int? ?? 2048,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  static List<LlmProviderConfig> get standardProviders => const [
        LlmProviderConfig(
          id: 'anthropic-sonnet-3-5',
          name: 'Claude 3.5 Sonnet',
          provider: 'anthropic',
          modelId: 'claude-3-5-sonnet-20241022',
          isConfigured: true,
          isDefault: true,
        ),
        LlmProviderConfig(
          id: 'openai-gpt-4o',
          name: 'OpenAI GPT-4o',
          provider: 'openai',
          modelId: 'gpt-4o',
          isConfigured: false,
        ),
        LlmProviderConfig(
          id: 'gemini-1-5-pro',
          name: 'Google Gemini 1.5 Pro',
          provider: 'google',
          modelId: 'gemini-1.5-pro-latest',
          isConfigured: false,
        ),
        LlmProviderConfig(
          id: 'ollama-local',
          name: 'Local Ollama (DeepSeek / Llama)',
          provider: 'ollama',
          modelId: 'deepseek-coder:6.7b',
          isConfigured: false,
        ),
      ];
}
