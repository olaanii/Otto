import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../errors/exceptions.dart';

/// Secure key-value storage wrapper for Clerk credentials, OAuth tokens, and LLM API keys.
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
              wOptions: WindowsOptions(useBackwardCompatibility: false),
            );

  static const String keyClerkToken = 'clerk_session_token';
  static const String keyClerkJwt = 'clerk_jwt';
  static const String keyUserId = 'clerk_user_id';
  static const String keyGithubToken = 'github_pat_token';
  static const String keyAnthropicKey = 'anthropic_api_key';
  static const String keyOpenAiKey = 'openai_api_key';
  static const String keyGeminiKey = 'gemini_api_key';
  static const String keyOpenRouterKey = 'openrouter_api_key';

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw StorageException('Failed to write to secure storage: $e');
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw StorageException('Failed to read from secure storage: $e');
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw StorageException('Failed to delete key from secure storage: $e');
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: keyClerkToken);
      await _storage.delete(key: keyClerkJwt);
      await _storage.delete(key: keyUserId);
    } catch (e) {
      throw StorageException('Failed to clear session tokens: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to purge secure storage: $e');
    }
  }
}
