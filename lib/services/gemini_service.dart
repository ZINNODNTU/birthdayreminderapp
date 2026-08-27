/// AI is intentionally unavailable until the authenticated backend is deployed.
///
/// The previous implementation called Gemini directly with a client-side API
/// key. That key has been removed. Core birthday features remain independent
/// from AI and continue to work offline.
class GeminiService {
  static Future<List<String>> getGiftSuggestions(String prompt) {
    return Future<List<String>>.error(
      StateError(
        'Dịch vụ AI đang được bảo trì. Các tính năng sinh nhật vẫn hoạt động bình thường.',
      ),
    );
  }

  static Future<List<String>> getWishSuggestions(String prompt) {
    return Future<List<String>>.error(
      StateError(
        'Dịch vụ AI đang được bảo trì. Các tính năng sinh nhật vẫn hoạt động bình thường.',
      ),
    );
  }
}
