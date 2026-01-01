/// 繁简转换服务
class ChineseConverterService {
  // 简体到繁体映射表（常用字）
  static const Map<String, String> _s2tMap = {
    '国': '國', '学': '學', '发': '發', '会': '會', '为': '為',
    '这': '這', '来': '來', '时': '時', '个': '個', '们': '們',
    '说': '說', '对': '對', '出': '出', '过': '過', '后': '後',
    '里': '裡', '还': '還', '进': '進', '头': '頭', '问': '問',
    '长': '長', '开': '開', '动': '動', '机': '機', '关': '關',
    '点': '點', '东': '東', '书': '書', '电': '電', '话': '話',
    '车': '車', '门': '門', '马': '馬', '鸟': '鳥', '鱼': '魚',
    '龙': '龍', '风': '風', '云': '雲', '飞': '飛', '见': '見',
    '亲': '親', '观': '觀', '红': '紅', '绿': '綠', '蓝': '藍',
    '黄': '黃', '银': '銀', '钱': '錢', '铁': '鐵', '钟': '鐘',
    '听': '聽', '写': '寫', '读': '讀', '语': '語', '词': '詞',
    '认': '認', '识': '識', '记': '記', '让': '讓', '请': '請',
    '谁': '誰', '什': '什', '么': '麼', '怎': '怎', '样': '樣',
    '经': '經', '济': '濟', '贸': '貿', '易': '易', '业': '業',
    '产': '產', '厂': '廠', '场': '場', '农': '農', '医': '醫',
    '药': '藥', '师': '師', '军': '軍', '队': '隊', '战': '戰',
    '历': '歷', '史': '史', '华': '華', '汉': '漢', '党': '黨',
    '团': '團', '组': '組', '织': '織', '统': '統', '领': '領',
    '导': '導', '干': '幹', '部': '部', '员': '員', '众': '眾',
    '万': '萬', '亿': '億', '数': '數', '计': '計', '算': '算',
  };

  // 繁体到简体映射表
  static final Map<String, String> _t2sMap = 
      _s2tMap.map((k, v) => MapEntry(v, k));

  /// 简体转繁体
  static String toTraditional(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_s2tMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// 繁体转简体
  static String toSimplified(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_t2sMap[char] ?? char);
    }
    return buffer.toString();
  }

  /// 检测文本是否包含繁体字
  static bool containsTraditional(String text) {
    for (int i = 0; i < text.length; i++) {
      if (_t2sMap.containsKey(text[i])) {
        return true;
      }
    }
    return false;
  }

  /// 检测文本是否包含简体字
  static bool containsSimplified(String text) {
    for (int i = 0; i < text.length; i++) {
      if (_s2tMap.containsKey(text[i])) {
        return true;
      }
    }
    return false;
  }
}
