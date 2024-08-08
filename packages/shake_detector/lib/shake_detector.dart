library shake_detector;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Callback for phone shakes
typedef PhoneShakeCallback = void Function();

/// ShakeDetector class for phone shake functionality
class ShakeDetector {
  bool _isPaused = false;
  int lastResumedTimeStamp = 0;

  /// User callback for phone shake
  final PhoneShakeCallback onShake;

  /// Shake detection threshold
  final double shakeThresholdGravity;

  /// Minimum time between shake
  final int shakeSlopTimeMS;

  /// Time before shake count resets in milliseconds
  final int shakeCountResetTime;

  /// Number of shakes required before shake is triggered
  final int minimumShakeCount;

  int mShakeTimestamp = DateTime.now().millisecondsSinceEpoch;
  int mShakeCount = 0;

  /// StreamSubscription for Accelerometer events
  StreamSubscription? streamSubscription;

  /// This constructor waits until [startListening] is called
  ShakeDetector.waitForStart({
    required this.onShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
    this.minimumShakeCount = 1,
  });

  /// This constructor automatically calls [startListening] and starts detection and callbacks.
  ShakeDetector.autoStart({
    required this.onShake,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
    this.minimumShakeCount = 1,
  }) {
    startListening();
  }

  /// Starts listening to accelerometer events
  void startListening() {
    streamSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        if (_isPaused) return;

        if (lastResumedTimeStamp + 500 >
            DateTime.now().millisecondsSinceEpoch) {
          return;
        }

        double x = event.x;
        double y = event.y;
        double z = event.z;

        double gX = x / 9.80665;
        double gY = y / 9.80665;
        double gZ = z / 9.80665;

        // gForce will be close to 1 when there is no movement.
        double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

        if (gForce > shakeThresholdGravity) {
          var now = DateTime.now().millisecondsSinceEpoch;
          // ignore shake events too close to each other (500ms)
          if (mShakeTimestamp + shakeSlopTimeMS > now) {
            return;
          }

          // reset the shake count after 3 seconds of no shakes
          if (mShakeTimestamp + shakeCountResetTime < now) {
            mShakeCount = 0;
          }

          mShakeTimestamp = now;
          mShakeCount++;

          if (mShakeCount >= minimumShakeCount) {
            onShake();
          }
        }
      },
    );
  }

  void pauseListening() {
    _isPaused = true;
    mShakeCount = 0;
    streamSubscription?.pause();
  }

  bool get isPaused {
    return _isPaused;
  }

  bool get isListening => !_isPaused;

  void resumeListening() {
    _isPaused = false;
    mShakeCount = 0;
    lastResumedTimeStamp = DateTime.now().millisecondsSinceEpoch;
    streamSubscription?.resume();
  }

  /// Stops listening to accelerometer events
  void stopListening() {
    _isPaused = true;
    streamSubscription?.cancel();
  }
}

class ShakeDetectWrap extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final PhoneShakeCallback onShake;
  final double shakeThresholdGravity;

  /// Minimum time between shake
  final int shakeSlopTimeMS;

  /// Time before shake count resets
  final int shakeCountResetTime;

  /// Number of shakes required before shake is triggered
  final int minimumShakeCount;

  const ShakeDetectWrap({
    super.key,
    required this.onShake,
    required this.child,
    this.shakeThresholdGravity = 2.7,
    this.shakeSlopTimeMS = 500,
    this.shakeCountResetTime = 3000,
    this.enabled = true,
    this.minimumShakeCount = 1,
  });

  @override
  State<ShakeDetectWrap> createState() => _ShakeDetectWrapState();
}

class _ShakeDetectWrapState extends State<ShakeDetectWrap> {
  late final ShakeDetector detector;
  late final AppLifecycleListener _listener;
  @override
  void initState() {
    if (widget.enabled) {
      detector = ShakeDetector.autoStart(
          onShake: widget.onShake,
          shakeThresholdGravity: widget.shakeThresholdGravity,
          shakeSlopTimeMS: widget.shakeSlopTimeMS,
          shakeCountResetTime: widget.shakeCountResetTime,
          minimumShakeCount: widget.minimumShakeCount);
      _listener = AppLifecycleListener(
        onStateChange: _onStateChanged,
      );
    }
    super.initState();
  }

  void _onStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.enabled &&
        detector.isPaused) {
      debugPrint('app resumed');
      detector.resumeListening();
    }
    if (state == AppLifecycleState.paused &&
        widget.enabled &&
        detector.isListening) {
      debugPrint('app paused');
      detector.pauseListening();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      detector.stopListening();
      _listener.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
