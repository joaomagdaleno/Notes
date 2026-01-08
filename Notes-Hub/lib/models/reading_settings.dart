import 'package:flutter/material.dart';

/// Model for reading mode settings.
///
/// Contains all customizable settings for the Zen reading mode.
@immutable
class ReadingSettings {
  /// Creates a new [ReadingSettings].
  const ReadingSettings({
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.letterSpacing = 0.0,
    this.textAlign = TextAlign.left,
    this.theme = ReadingTheme.light,
    this.fontFamily = 'Default',
    this.paragraphSpacing = 16.0,
    this.nightLightEnabled = false,
    this.nightLightIntensity = 0.3,
  });

  /// Creates [ReadingSettings] from a JSON map.
  factory ReadingSettings.fromJson(Map<String, dynamic> json) {
    return ReadingSettings(
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.6,
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? 0.0,
      textAlign: TextAlign.values.firstWhere(
        (t) => t.name == json['textAlign'],
        orElse: () => TextAlign.left,
      ),
      theme: ReadingTheme.values.firstWhere(
        (t) => t.name == json['theme'],
        orElse: () => ReadingTheme.light,
      ),
      fontFamily: json['fontFamily'] as String? ?? 'Default',
      paragraphSpacing: (json['paragraphSpacing'] as num?)?.toDouble() ?? 16.0,
      nightLightEnabled: json['nightLightEnabled'] as bool? ?? false,
      nightLightIntensity:
          (json['nightLightIntensity'] as num?)?.toDouble() ?? 0.3,
    );
  }

  /// Default settings.
  static const ReadingSettings defaults = ReadingSettings();

  /// Font size in logical pixels.
  final double fontSize;

  /// Line height multiplier.
  final double lineHeight;

  /// Letter spacing in logical pixels.
  final double letterSpacing;

  /// Text alignment.
  final TextAlign textAlign;

  /// Reading theme.
  final ReadingTheme theme;

  /// Font family name.
  final String fontFamily;

  /// Paragraph spacing in logical pixels.
  final double paragraphSpacing;

  /// Whether night light filter is enabled.
  final bool nightLightEnabled;

  /// Night light intensity (0.0 to 1.0).
  final double nightLightIntensity;

  /// Converts this to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'textAlign': textAlign.name,
      'theme': theme.name,
      'fontFamily': fontFamily,
      'paragraphSpacing': paragraphSpacing,
      'nightLightEnabled': nightLightEnabled,
      'nightLightIntensity': nightLightIntensity,
    };
  }

  /// Creates a copy with optional new values.
  ReadingSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    TextAlign? textAlign,
    ReadingTheme? theme,
    String? fontFamily,
    double? paragraphSpacing,
    bool? nightLightEnabled,
    double? nightLightIntensity,
  }) {
    return ReadingSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      textAlign: textAlign ?? this.textAlign,
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      nightLightEnabled: nightLightEnabled ?? this.nightLightEnabled,
      nightLightIntensity: nightLightIntensity ?? this.nightLightIntensity,
    );
  }

  /// Gets the text style based on current settings.
  TextStyle getTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily == 'Default' ? null : fontFamily,
      color: theme.textColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingSettings &&
        other.fontSize == fontSize &&
        other.lineHeight == lineHeight &&
        other.letterSpacing == letterSpacing &&
        other.textAlign == textAlign &&
        other.theme == theme &&
        other.fontFamily == fontFamily &&
        other.paragraphSpacing == paragraphSpacing &&
        other.nightLightEnabled == nightLightEnabled &&
        other.nightLightIntensity == nightLightIntensity;
  }

  @override
  int get hashCode {
    return Object.hash(
      fontSize,
      lineHeight,
      letterSpacing,
      textAlign,
      theme,
      fontFamily,
      paragraphSpacing,
      nightLightEnabled,
      nightLightIntensity,
    );
  }
}

/// Reading theme options.
enum ReadingTheme {
  /// Light theme with white background.
  light,

  /// Sepia theme with warm tinted background.
  sepia,

  /// Dark theme with dark background.
  dark
  ;

  /// Gets the background color for this theme.
  Color get backgroundColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.white;
      case ReadingTheme.sepia:
        return const Color(0xFFF5E6D3);
      case ReadingTheme.dark:
        return const Color(0xFF1A1A1A);
    }
  }

  /// Gets the text color for this theme.
  Color get textColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.black87;
      case ReadingTheme.sepia:
        return const Color(0xFF5D4037);
      case ReadingTheme.dark:
        return const Color(0xFFE0E0E0);
    }
  }

  /// Gets the accent color for this theme.
  Color get accentColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.blue;
      case ReadingTheme.sepia:
        return const Color(0xFF8D6E63);
      case ReadingTheme.dark:
        return Colors.tealAccent;
    }
  }
}
