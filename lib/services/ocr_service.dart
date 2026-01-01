import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR 文字识别服务
class OcrService {
  static TextRecognizer? _recognizer;

  /// 初始化识别器（支持中英文）
  static void _initRecognizer() {
    // 使用中文脚本识别器，同时也能识别英文
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
  }

  /// 释放资源
  static Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }

  /// 从图片文件识别文字
  static Future<OcrResult> recognizeFromFile(String imagePath) async {
    try {
      _initRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      return await _recognizeImage(inputImage);
    } catch (e) {
      return OcrResult(success: false, text: '', errorMessage: '识别失败: $e');
    }
  }

  /// 从图片字节识别文字
  static Future<OcrResult> recognizeFromBytes(
    List<int> bytes,
    int width,
    int height,
  ) async {
    try {
      _initRecognizer();
      
      // 保存临时文件
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);
      
      final result = await recognizeFromFile(tempFile.path);
      
      // 清理临时文件
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      return result;
    } catch (e) {
      return OcrResult(success: false, text: '', errorMessage: '识别失败: $e');
    }
  }

  /// 识别图片
  static Future<OcrResult> _recognizeImage(InputImage inputImage) async {
    try {
      final result = await _recognizer!.processImage(inputImage);
      
      if (result.text.isNotEmpty) {
        return OcrResult(
          success: true,
          text: result.text,
          blocks: result.blocks.map((b) => TextBlockInfo(
            text: b.text,
            boundingBox: b.boundingBox,
          )).toList(),
        );
      }

      return OcrResult(
        success: false,
        text: '',
        errorMessage: '未识别到文字',
      );
    } catch (e) {
      return OcrResult(success: false, text: '', errorMessage: '识别错误: $e');
    }
  }
}

/// OCR 识别结果
class OcrResult {
  final bool success;
  final String text;
  final String? errorMessage;
  final List<TextBlockInfo> blocks;

  OcrResult({
    required this.success,
    required this.text,
    this.errorMessage,
    this.blocks = const [],
  });
}

/// 文本块信息
class TextBlockInfo {
  final String text;
  final Rect boundingBox;

  TextBlockInfo({
    required this.text,
    required this.boundingBox,
  });
}
