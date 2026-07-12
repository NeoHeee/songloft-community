import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_provider.dart';
import '../queue_page.dart';
import 'mobile_player.dart';

/// 为现有全屏播放器叠加不抢占手势竞技场的封面快捷手势。
///
/// 使用 Listener 监听原始指针，因此不会破坏 PageView 左右切换、歌词滚动、
/// 进度条拖动以及原有下滑收起：
/// - 封面区域上滑：打开播放队列
/// - 封面区域双击：播放/暂停
class MobilePlayerGestureHost extends ConsumerStatefulWidget {
  const MobilePlayerGestureHost({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                const MobilePlayerGestureHost(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
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
  static const _tapSlop = 14.0;
  static const _swipeThreshold = 72.0;

  int? _trackedPointer;
  Offset? _pointerStart;
  Offset? _pointerLatest;
  DateTime? _pointerStartedAt;
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;

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
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _trackedPointer) return;
    _pointerLatest = event.localPosition;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _trackedPointer) return;

    final start = _pointerStart;
    final end = _pointerLatest ?? event.localPosition;
    final startedAt = _pointerStartedAt;
    _clearTrackedPointer();

    if (start == null || startedAt == null) return;

    final delta = end - start;
    final isVerticalSwipe =
        delta.dy.abs() > delta.dx.abs() * 1.25 &&
        delta.dy < -_swipeThreshold;

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
      HapticFeedback.selectionClick();
      ref.read(playerStateProvider.notifier).togglePlay();
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
    _trackedPointer = null;
    _pointerStart = null;
    _pointerLatest = null;
    _pointerStartedAt = null;
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
