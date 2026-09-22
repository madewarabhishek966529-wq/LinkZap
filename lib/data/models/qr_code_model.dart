import 'package:flutter/material.dart';

enum QrType {
  url,
  text,
  phone,
  email,
  wifi;

  String get displayName {
    switch (this) {
      case QrType.url:
        return 'URL';
      case QrType.text:
        return 'Text';
      case QrType.phone:
        return 'Phone';
      case QrType.email:
        return 'Email';
      case QrType.wifi:
        return 'Wi-Fi';
    }
  }

  IconData get icon {
    switch (this) {
      case QrType.url:
        return Icons.link_rounded;
      case QrType.text:
        return Icons.notes_rounded;
      case QrType.phone:
        return Icons.phone_rounded;
      case QrType.email:
        return Icons.email_rounded;
      case QrType.wifi:
        return Icons.wifi_rounded;
    }
  }
}

enum DotStyle {
  square,
  rounded,
  circle;

  String get displayName {
    switch (this) {
      case DotStyle.square:
        return 'Square';
      case DotStyle.rounded:
        return 'Rounded';
      case DotStyle.circle:
        return 'Circle';
    }
  }
}

enum EyeStyle {
  square,
  rounded,
  circle;

  String get displayName {
    switch (this) {
      case EyeStyle.square:
        return 'Square';
      case EyeStyle.rounded:
        return 'Rounded';
      case EyeStyle.circle:
        return 'Circle';
    }
  }
}

enum QrErrorCorrection {
  low('L'),
  medium('M'),
  quartile('Q'),
  high('H');

  final String code;
  const QrErrorCorrection(this.code);
}

class QrCodeModel {
  final int? id;
  final QrType type;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int? collectionId;
  final Color foregroundColor;
  final Color backgroundColor;
  final DotStyle dotStyle;
  final EyeStyle eyeStyle;
  final QrErrorCorrection errorCorrection;
  final String? logoPath;
  final bool logoIsRounded;
  final double margin;

  QrCodeModel({
    this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.collectionId,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.dotStyle = DotStyle.square,
    this.eyeStyle = EyeStyle.square,
    this.errorCorrection = QrErrorCorrection.medium,
    this.logoPath,
    this.logoIsRounded = true,
    this.margin = 12.0,
  });

  QrCodeModel copyWith({
    int? id,
    QrType? type,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? collectionId,
    Color? foregroundColor,
    Color? backgroundColor,
    DotStyle? dotStyle,
    EyeStyle? eyeStyle,
    QrErrorCorrection? errorCorrection,
    String? logoPath,
    bool? logoIsRounded,
    double? margin,
  }) {
    return QrCodeModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      collectionId: collectionId ?? this.collectionId,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      dotStyle: dotStyle ?? this.dotStyle,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      errorCorrection: errorCorrection ?? this.errorCorrection,
      logoPath: logoPath ?? this.logoPath,
      logoIsRounded: logoIsRounded ?? this.logoIsRounded,
      margin: margin ?? this.margin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'collection_id': collectionId,
      'foreground_color': foregroundColor.toARGB32(),
      'background_color': backgroundColor.toARGB32(),
      'dot_style': dotStyle.name,
      'eye_style': eyeStyle.name,
      'error_correction': errorCorrection.code,
      'logo_path': logoPath,
      'logo_is_rounded': logoIsRounded ? 1 : 0,
      'margin': margin,
    };
  }

  factory QrCodeModel.fromMap(Map<String, dynamic> map) {
    return QrCodeModel(
      id: map['id'] as int?,
      type: QrType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QrType.text,
      ),
      title: map['title'] as String? ?? 'QR Code',
      content: map['content'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      collectionId: map['collection_id'] as int?,
      foregroundColor: Color(map['foreground_color'] as int? ?? Colors.black.toARGB32()),
      backgroundColor: Color(map['background_color'] as int? ?? Colors.white.toARGB32()),
      dotStyle: DotStyle.values.firstWhere(
        (e) => e.name == map['dot_style'],
        orElse: () => DotStyle.square,
      ),
      eyeStyle: EyeStyle.values.firstWhere(
        (e) => e.name == map['eye_style'],
        orElse: () => EyeStyle.square,
      ),
      errorCorrection: QrErrorCorrection.values.firstWhere(
        (e) => e.code == map['error_correction'],
        orElse: () => QrErrorCorrection.medium,
      ),
      logoPath: map['logo_path'] as String?,
      logoIsRounded: (map['logo_is_rounded'] as int? ?? 1) == 1,
      margin: (map['margin'] as num?)?.toDouble() ?? 12.0,
    );
  }
}
