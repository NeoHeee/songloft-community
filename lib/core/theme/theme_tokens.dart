import 'package:flutter/material.dart';

@immutable
class SongloftThemeTokens extends ThemeExtension<SongloftThemeTokens> {
  final List<Color> playerGradient;
  final double cardRadius;
  final double controlRadius;
  final double navigationRadius;

  const SongloftThemeTokens({
    required this.playerGradient,
    required this.cardRadius,
    required this.controlRadius,
    required this.navigationRadius,
  });

  static SongloftThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<SongloftThemeTokens>() ??
        const SongloftThemeTokens(
          playerGradient: [Color(0xFF7C5CFF), Color(0xFF4C7DFF)],
          cardRadius: 22,
          controlRadius: 15,
          navigationRadius: 16,
        );
  }

  @override
  SongloftThemeTokens copyWith({
    List<Color>? playerGradient,
    double? cardRadius,
    double? controlRadius,
    double? navigationRadius,
  }) {
    return SongloftThemeTokens(
      playerGradient: playerGradient ?? this.playerGradient,
      cardRadius: cardRadius ?? this.cardRadius,
      controlRadius: controlRadius ?? this.controlRadius,
      navigationRadius: navigationRadius ?? this.navigationRadius,
    );
  }

  @override
  SongloftThemeTokens lerp(covariant SongloftThemeTokens? other, double t) {
    if (other == null) return this;
    return SongloftThemeTokens(
      playerGradient: [
        Color.lerp(playerGradient[0], other.playerGradient[0], t) ??
            playerGradient[0],
        Color.lerp(playerGradient[1], other.playerGradient[1], t) ??
            playerGradient[1],
      ],
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      controlRadius: controlRadius + (other.controlRadius - controlRadius) * t,
      navigationRadius:
          navigationRadius + (other.navigationRadius - navigationRadius) * t,
    );
  }
}
