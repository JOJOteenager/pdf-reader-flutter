import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_text_recognition_chinese/google_mlkit_text_recognition_chinese.dart';

/// OCR 文字识别服务
class OcrService {
  static TextRecognizer? _latinRecognizer;
  static TextRecognizer? _chineseRecognizer;

  /// 初始化识别器
  static void _initRecognizers() {
    _latinRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    _chineseRecognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
  }

  /// 释放资源
  static Future<void> dispose() async {
    await _latinRecognizer?.close();
    await _chineseRecognizer?.close();
    _latinRecognizer = null;
    _chineseRecognizer = null;
  }

  /// 从图片文件识别文字
  static Future<OcrResult> recognizeFromFile(String imagePath) async {
    try {
      _initRecognizers();
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
      _initRecognizers();
      
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
      // 先尝试中文识别
      final chineseResult = await _chineseRecognizer!.processImage(inputImage);
      
      if (chineseResult.text.isNotEmpty) {
        return OcrResult(
          success: true,
          text: chineseResult.text,
          blocks: chineseResult.blocks.map((b) => TextBlockInfo(
            text: b.text,
            boundingBox: b.boundingBox,
          )).toList(),
        );
      }

      // 如果中文识别为空，尝试拉丁文识别
      final latinResult = await _latinRecognizer!.processImage(inputImage);
      
      if (latinResult.text.isNotEmpty) {
        return OcrResult(
          success: true,
          text: latinResult.text,
          blocks: latinResult.blocks.map((b) => TextBlockInfo(
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
