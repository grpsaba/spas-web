import 'package:flutter/material.dart';

class AppBuildInfo {
  static const String _buildLabel = String.fromEnvironment(
    'SPAS_BUILD_LABEL',
    defaultValue: 'dev',
  );

  static String get displayLabel {
    final label = _buildLabel.trim();
    if (label.isEmpty || label == 'dev') return 'Version dev';
    return label.startsWith('V') ? label : 'V$label';
  }
}

class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({
    super.key,
    this.color,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.textAlign,
  });

  final Color? color;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppBuildInfo.displayLabel,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
