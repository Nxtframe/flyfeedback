import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'feedback_panel.dart';

/// Callback when feedback is submitted
typedef FeedbackSubmitCallback = FutureOr<void> Function(
  String feedback, {
  Uint8List? screenshot,
  Map<String, dynamic>? extras,
});

/// A feedback widget that wraps your application to enable feedback functionality.
///
/// Wrap your app like this:
/// ```dart
/// void main() {
///   runApp(
///     FeedbackWrapper(
///       child: MaterialApp(
///         title: 'My App',
///         home: MyHomePage(),
///       ),
///       onFeedbackSubmitted: (feedback, {screenshot, extras}) async {
///         // Handle feedback submission
///         debugPrint('Feedback: $feedback');
///       },
///     ),
///   );
/// }
/// ```
class FeedbackWrapper extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// Called when the user submits feedback
  final FeedbackSubmitCallback onFeedbackSubmitted;

  /// The mode for the feedback UI
  final FeedbackMode mode;

  /// The pixel ratio for screenshot capture
  final double pixelRatio;

  /// Creates a [FeedbackWrapper] widget.
  const FeedbackWrapper({
    super.key,
    required this.child,
    required this.onFeedbackSubmitted,
    this.mode = FeedbackMode.draw,
    this.pixelRatio = 3.0,
  }) : assert(pixelRatio > 0, 'pixelRatio must be greater than 0');

  /// The state from the closest instance of this class that encloses the given context.
  static FeedbackWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<FeedbackWrapperState>();
  }

  @override
  FeedbackWrapperState createState() => FeedbackWrapperState();
}

/// The current feedback mode
enum FeedbackMode {
  /// Draw mode for drawing on the screenshot
  draw,

  /// Navigate mode for interacting with the app
  navigate,
}

/// The state for [FeedbackWrapper]
class FeedbackWrapperState extends State<FeedbackWrapper> {
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isFeedbackVisible = false;
  OverlayEntry? _overlayEntry;
  final Map<String, dynamic> _extras = {};

  /// Shows the feedback panel with optional extra data
  void showFeedbackPanel({Map<String, dynamic>? extras}) async {
    if (_isFeedbackVisible) return;

    setState(() {
      _isFeedbackVisible = true;
      if (extras != null) {
        _extras.addAll(extras);
      }
    });

    // Wait for the next frame to ensure the overlay can be inserted
    await Future.delayed(Duration.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: hideFeedbackPanel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black54),
            ),
            // Feedback panel
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                  maxHeight: 600,
                ),
                margin: const EdgeInsets.all(24),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                  child: FeedbackPanel(
                    key: const ValueKey('feedback_panel'),
                    screenshotKey: _screenshotKey,
                    onSubmit: (feedback, screenshot) async {
                      try {
                        await widget.onFeedbackSubmitted(
                          feedback,
                          screenshot: screenshot,
                          extras: _extras,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Feedback submitted!'),
                            ),
                          );
                        }
                        return true;
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit feedback: $e'),
                            ),
                          );
                        }
                        return false;
                      } finally {
                        if (mounted) {
                          hideFeedbackPanel();
                        }
                      }
                    },
                    onClose: hideFeedbackPanel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
  }

  /// Hides the feedback panel if it's visible
  void hideFeedbackPanel() {
    if (!_isFeedbackVisible) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isFeedbackVisible = false;
      _extras.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _screenshotKey,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }
}
