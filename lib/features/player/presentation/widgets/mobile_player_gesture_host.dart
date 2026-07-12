import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/accessibility.dart';
import '../queue_page.dart';
import '../utils/player_song_actions.dart';
import 'mobile_player.dart';

/// 为现有全屏播放器叠加不抢占 PageView 的封面快捷手势。
///
/// - 封面区域上滑：打开播放队列
/// - 封面区域双击：收藏或取消收藏当前歌曲
/// - 封面区域长按：打开当前歌曲操作菜单
class MobilePlayerGestureHost extends ConsumerStatefulWidget {
  const MobilePlayerGestureHost({super.key});

  static Future<void> show(BuildContext context) {
    final reduceMotion = AppAccessibility.reduceMotionOf(context);
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 280),
        reverseTransitionDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MobilePlayerGestureHost(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (reduceMotion) return child;
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<MobilePlayerGestureHost> createState() =>
      _MobilePlayerGestureHostState();
}

class _MobilePlayerGestureHostState
    extends ConsumerState<MobilePlayerGestureHost> {
  static const _doubleTapWindow = Duration(milliseconds: 320);
  static const _longPressDelay = Duration(milliseconds: 520);
  static const _tapSlop = 14.0;
  static const _swipeThreshold = 72.0;

  int? _trackedPointer;
  Offset? _pointerStart;
  Offset? _pointerLatest;
  DateTime? _pointerStartedAt;
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;
  Timer? _longPressTimer;
  bool _longPressTriggered = false;

  bool _isInsideCoverGestureArea(Offset localPosition) {
    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + 62;
    final bottom = mediaQuery.size.height * 0.64;
    return localPosition.dy >= top && localPosition.dy <= bottom;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_trackedPointer != null ||
        !_isInsideCoverGestureArea(event.localPosition)) {
      return;
    }

    _trackedPointer = event.pointer;
    _pointerStart = event.localPosition;
    _pointerLatest = event.localPosition;
    _pointerStartedAt = DateTime.now();
    _longPressTriggered = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDelay, () {
      final start = _pointerStart;
      final latest = _pointerLatest;
      if (!mounted ||
          _trackedPointer == null ||
          start == null ||
          latest == null ||
          (latest - start).distance > _tapSlop) {
        return;
      }
      _longPressTriggered = true;
      HapticFeedback.mediumImpact();
      unawaited(showCurrentSongActionsSheet(context, ref));
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackedPointer) return;
    _pointerLatest = event.localPosition;
    final start = _pointerStart;
    if (start != null && (event.localPosition - start).distance > _tapSlop) {
      _longPressTimer?.cancel();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _trackedPointer) return;

    final start = _pointerStart;
    final end = _pointerLatest ?? event.localPosition;
    final startedAt = _pointerStartedAt;
    final longPressTriggered = _longPressTriggered;
    _clearTrackedPointer();

    if (longPressTriggered || start == null || startedAt == null) return;

    final delta = end - start;
    final isVerticalSwipe =
        delta.dy.abs() > delta.dx.abs() * 1.25 && delta.dy < -_swipeThreshold;

    if (isVerticalSwipe) {
      HapticFeedback.mediumImpact();
      QueueBottomSheet.show(context);
      return;
    }

    final elapsed = DateTime.now().difference(startedAt);
    final isTap =
        delta.distance <= _tapSlop &&
        elapsed <= const Duration(milliseconds: 260);
    if (!isTap) return;

    final now = DateTime.now();
    final previousTapAt = _lastTapAt;
    final previousTapPosition = _lastTapPosition;
    final isDoubleTap =
        previousTapAt != null &&
        previousTapPosition != null &&
        now.difference(previousTapAt) <= _doubleTapWindow &&
        (start - previousTapPosition).distance <= 40;

    if (isDoubleTap) {
      _lastTapAt = null;
      _lastTapPosition = null;
      unawaited(toggleCurrentSongFavorite(context, ref));
      return;
    }

    _lastTapAt = now;
    _lastTapPosition = start;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _trackedPointer) {
      _clearTrackedPointer();
    }
  }

  void _clearTrackedPointer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _trackedPointer = null;
    _pointerStart = null;
    _pointerLatest = null;
    _pointerStartedAt = null;
    _longPressTriggered = false;
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: const MobilePlayer(),
    );
  }
}
