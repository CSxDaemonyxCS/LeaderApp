import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_palette.dart';

class ThemeState {
  const ThemeState({required this.palette, required this.mode});
  final PaletteId palette;
  final ThemeMode mode;

  ThemeState copyWith({PaletteId? palette, ThemeMode? mode}) =>
      ThemeState(palette: palette ?? this.palette, mode: mode ?? this.mode);
}

class ThemeController extends Notifier<ThemeState> {
  @override
  ThemeState build() =>
      const ThemeState(palette: PaletteId.slate, mode: ThemeMode.light);

  void setPalette(PaletteId p) => state = state.copyWith(palette: p);
  void setMode(ThemeMode m) => state = state.copyWith(mode: m);
  void toggleMode() => state = state.copyWith(
        mode: state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(ThemeController.new);
