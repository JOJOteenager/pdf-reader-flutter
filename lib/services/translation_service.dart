import 'dart:convert';
import 'package:http/http.dart' as http;

/// 翻译服务
class TranslationService {
  // 使用免费的翻译API
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';

  /// 翻译文本
  /// [text] 要翻译的文本
  /// [from] 源语言代码 (en, zh, ja, ko, etc.)
  /// [to] 目标语言代码
  static Future<TranslationResult> translate(
    String text, {
    String from = 'en',
    String to = 'zh-CN',
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult(
        success: false,
        originalText: text,
        translatedText: '',
        errorMessage: '文本不能为空',
      );
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$from|$to',
      });

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('请求超时'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translatedText = data['responseData']['translatedText'] as String?;
        
        if (translatedText != null && translatedText.isNotEmpty) {
          return TranslationResult(
            success: true,
            originalText: text,
            translatedText: translatedText,
          );
        } else {
          return TranslationResult(
            success: false,
            originalText: text,
            translatedText: '',
            errorMessage: '翻译结果为空',
          );
        }
      } else {
        return TranslationResult(
          success: false,
          originalText: text,
          translatedText: '',
          errorMessage: '服务器错误: ${response.statusCode}',
        );
      }
    } catch (e) {
      return TranslationResult(
        success: false,
        originalText: text,
        translatedText: '',
        errorMessage: '翻译失败: $e',
      );
    }
  }

  /// 英译中
  static Future<TranslationResult> englishToChinese(String text) {
    return translate(text, from: 'en', to: 'zh-CN');
  }

  /// 中译英
  static Future<TranslationResult> chineseToEnglish(String text) {
    return translate(text, from: 'zh-CN', to: 'en');
  }

  /// 日译中
  static Future<TranslationResult> japaneseToChinese(String text) {
    return translate(text, from: 'ja', to: 'zh-CN');
  }
}

/// 翻译结果
class TranslationResult {
  final bool success;
  final String originalText;
  final String translatedText;
  final String? errorMessage;

  TranslationResult({
    required this.success,
    required this.originalText,
    required this.translatedText,
    this.errorMessage,
  });
}
