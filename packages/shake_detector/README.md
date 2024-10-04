# shake_detector

A flutter package to detect phone shakes, with pause and resume listening when the app is in background and foreground respectively.

## Usage

### 1. Use as Widget
```dart 
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ShakeGesture Example')),
      body: Center(
        // The start.
        child: ShakeDetectWrap(
          enabled: true,
          onShake: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shake!')),
            );
          },
          child: const Center(
            child: OutlinedButton(
              onPressed: ShakeGestureTestHelperExtension.simulateShake,
              child: Text('Simulate Shake'),
            ),
          ),
        ),
		    // The end.
      ),
    );
  }
}

```

### 2. Use as Listener

To listen to phone shake:

```dart
ShakeDetector detector = ShakeDetector.autoStart(
    onShake: () {
        // Do stuff on phone shake
    }
);
```

OR

This will wait for user to call `startListening()` to start listening to phone shake:
```dart
ShakeDetector detector = ShakeDetector.waitForStart(
    onShake: () {
        // Do stuff on phone shake
    }
);

// start listening later on, after using waitForStart constructor
detector.startListening();
```

Control Detector:
```dart
// usually you don’t start listening but used in constructor
detector.startListening();

// pause shake listening for a while (e.g. when app is in background)
detector.pauseListening();

// resume shake listening after pause
detector.resumeListening();

// stop shake detection
// this will cancel the stream subscription 
detector.stopListening();

```


