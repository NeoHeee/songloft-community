import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';
import 'theme_pack.dart';

@immutable
class ThemePackState {
  final List<SongloftThemePack> packs;
  final String selectedId;
  final bool isLoading;
  final String? errorMessage;

  const ThemePackState({
    required this.packs,
    required this.selectedId,
    this.isLoading = false,
    this.errorMessage,
  });

  factory ThemePackState.initial() {
    return const ThemePackState(
      packs: SongloftThemePacks.builtIn,
      selectedId: defaultThemePackId,
      isLoading: true,
    );
  }

  SongloftThemePack get selectedPack {
    for (final pack in packs) {
      if (pack.id == selectedId) return pack;
    }
    return SongloftThemePacks.classic;
  }

  List<SongloftThemePack> get customPacks {
    return packs.where((pack) => !pack.isBuiltIn).toList(growable: false);
  }

  ThemePackState copyWith({
    List<SongloftThemePack>? packs,
    String? selectedId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ThemePackState(
      packs: packs ?? this.packs,
      selectedId: selectedId ?? this.selectedId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ThemePackNotifier extends Notifier<ThemePackState> {
  static const int maxCustomThemePacks = 32;
  static const int maxThemePackBytes = 128 * 1024;

  @override
  ThemePackState build() {
    Future.microtask(_load);
    return ThemePackState.initial();
  }

  Future<void> _load() async {
    try {
      final prefs = await AppPreferences.create();
      final custom = <SongloftThemePack>[];
      for (final item in prefs.getCustomThemePacks()) {
        try {
          custom.add(SongloftThemePack.fromJson(item));
        } catch (e) {
          debugPrint('[ThemePack] 跳过无效本地主题包: $e');
        }
      }

      final packs = List<SongloftThemePack>.unmodifiable([
        ...SongloftThemePacks.builtIn,
        ...custom,
      ]);
      final storedId = prefs.getSelectedThemePackId();
      final selectedId = packs.any((pack) => pack.id == storedId)
          ? storedId
          : defaultThemePackId;

      state = ThemePackState(
        packs: packs,
        selectedId: selectedId,
      );
    } catch (e) {
      state = ThemePackState(
        packs: SongloftThemePacks.builtIn,
        selectedId: defaultThemePackId,
        errorMessage: '加载主题包失败：$e',
      );
    }
  }

  Future<void> selectThemePack(String id) async {
    if (!state.packs.any((pack) => pack.id == id)) {
      throw const ThemePackFormatException('未找到该主题包');
    }

    state = state.copyWith(selectedId: id, clearError: true);
    try {
      final prefs = await AppPreferences.create();
      await prefs.setSelectedThemePackId(id);
    } catch (e) {
      state = state.copyWith(errorMessage: '保存主题选择失败：$e');
      rethrow;
    }
  }

  Future<SongloftThemePack> installThemePack(String source) async {
    final byteLength = utf8.encode(source).length;
    if (byteLength > maxThemePackBytes) {
      throw const ThemePackFormatException('主题包不能超过 128 KB');
    }

    final pack = SongloftThemePack.fromJsonString(source);
    if (SongloftThemePacks.findBuiltIn(pack.id) != null) {
      throw const ThemePackFormatException('自定义主题包不能使用内置主题的 id');
    }

    final custom = List<SongloftThemePack>.from(state.customPacks);
    final existingIndex = custom.indexWhere((item) => item.id == pack.id);
    if (existingIndex >= 0) {
      custom[existingIndex] = pack;
    } else {
      if (custom.length >= maxCustomThemePacks) {
        throw const ThemePackFormatException('最多安装 32 个自定义主题包');
      }
      custom.add(pack);
    }

    custom.sort((a, b) => a.name.compareTo(b.name));
    final packs = List<SongloftThemePack>.unmodifiable([
      ...SongloftThemePacks.builtIn,
      ...custom,
    ]);

    state = ThemePackState(packs: packs, selectedId: pack.id);
    await _persist(custom, selectedId: pack.id);
    return pack;
  }

  Future<void> removeThemePack(String id) async {
    final target = state.packs.where((pack) => pack.id == id).firstOrNull;
    if (target == null) return;
    if (target.isBuiltIn) {
      throw const ThemePackFormatException('内置主题不能删除');
    }

    final custom = state.customPacks.where((pack) => pack.id != id).toList();
    final selectedId = state.selectedId == id
        ? defaultThemePackId
        : state.selectedId;
    final packs = List<SongloftThemePack>.unmodifiable([
      ...SongloftThemePacks.builtIn,
      ...custom,
    ]);

    state = ThemePackState(packs: packs, selectedId: selectedId);
    await _persist(custom, selectedId: selectedId);
  }

  Future<void> _persist(
    List<SongloftThemePack> custom, {
    required String selectedId,
  }) async {
    try {
      final prefs = await AppPreferences.create();
      await prefs.setCustomThemePacks(
        custom.map((pack) => pack.toJson()).toList(growable: false),
      );
      await prefs.setSelectedThemePackId(selectedId);
    } catch (e) {
      state = state.copyWith(errorMessage: '保存主题包失败：$e');
      rethrow;
    }
  }
}

final themePackProvider = NotifierProvider<ThemePackNotifier, ThemePackState>(
  ThemePackNotifier.new,
);
