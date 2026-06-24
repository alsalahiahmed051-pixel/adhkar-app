/// type values: "text" | "image" | "audio" | "file"
class DhikrItem {
  final String id;
  final String category;
  final String type;
  final String title;
  final String source;
  final String target; // recommended repeat count, e.g. "33 مرة" — informational only
  final String text;
  final String mediaUrl; // Firebase Storage download URL (or http link if user pasted one)
  final String caption;
  final String fileName;
  final int count;
  final int createdAt;
  final String? shareCode;
  final bool isBuiltin;

  const DhikrItem({
    required this.id,
    required this.category,
    required this.type,
    required this.title,
    this.source = '',
    this.target = '',
    this.text = '',
    this.mediaUrl = '',
    this.caption = '',
    this.fileName = '',
    this.count = 0,
    required this.createdAt,
    this.shareCode,
    this.isBuiltin = false,
  });

  DhikrItem copyWith({
    String? id,
    String? category,
    int? count,
    String? shareCode,
  }) =>
      DhikrItem(
        id: id ?? this.id,
        category: category ?? this.category,
        type: type,
        title: title,
        source: source,
        target: target,
        text: text,
        mediaUrl: mediaUrl,
        caption: caption,
        fileName: fileName,
        count: count ?? this.count,
        createdAt: createdAt,
        shareCode: shareCode ?? this.shareCode,
        isBuiltin: isBuiltin,
      );

  factory DhikrItem.fromMap(Map<String, dynamic> map, String docId) => DhikrItem(
        id: docId,
        category: map['category'] ?? 'morning',
        type: map['type'] ?? 'text',
        title: map['title'] ?? '',
        source: map['source'] ?? '',
        target: map['target'] ?? '',
        text: map['text'] ?? '',
        mediaUrl: map['mediaUrl'] ?? '',
        caption: map['caption'] ?? '',
        fileName: map['fileName'] ?? '',
        count: (map['count'] ?? 0) as int,
        createdAt: (map['createdAt'] ?? 0) as int,
        shareCode: map['shareCode'] as String?,
        isBuiltin: false,
      );

  Map<String, dynamic> toMap() => {
        'category': category,
        'type': type,
        'title': title,
        'source': source,
        'target': target,
        'text': text,
        'mediaUrl': mediaUrl,
        'caption': caption,
        'fileName': fileName,
        'count': count,
        'createdAt': createdAt,
        'shareCode': shareCode,
      };

  factory DhikrItem.fromJson(Map<String, dynamic> json) => DhikrItem(
        id: json['id'],
        category: json['category'],
        type: json['type'],
        title: json['title'],
        source: json['source'] ?? '',
        target: json['target'] ?? '',
        text: json['text'] ?? '',
        mediaUrl: json['mediaUrl'] ?? '',
        caption: json['caption'] ?? '',
        fileName: json['fileName'] ?? '',
        count: json['count'] ?? 0,
        createdAt: json['createdAt'] ?? 0,
        shareCode: json['shareCode'],
        isBuiltin: json['isBuiltin'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'type': type,
        'title': title,
        'source': source,
        'target': target,
        'text': text,
        'mediaUrl': mediaUrl,
        'caption': caption,
        'fileName': fileName,
        'count': count,
        'createdAt': createdAt,
        'shareCode': shareCode,
        'isBuiltin': isBuiltin,
      };
}
