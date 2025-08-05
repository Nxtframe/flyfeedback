import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'feedback_panel.dart';

// A simple typedef for the feedback submission callback
typedef FeedbackSubmitCallback =
    void Function(String feedback, Uint8List? screenshot);

class FeedbackWrapper extends StatefulWidget {
  final Widget child;
  final FeedbackSubmitCallback onFeedbackSubmitted;

  const FeedbackWrapper({
    super.key,
    required this.child,
    required this.onFeedbackSubmitted,
  });

  @override
  _FeedbackWrapperState createState() => _FeedbackWrapperState();

  static _FeedbackWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<_FeedbackWrapperState>();
  }
}

class _FeedbackWrapperState extends State<FeedbackWrapper> {
  final GlobalKey _screenshotKey = GlobalKey();
  bool _showFeedbackPanel = false;
  OverlayEntry? _overlayEntry;

  void showFeedbackPanel() {
    if (_showFeedbackPanel) return;

    setState(() => _showFeedbackPanel = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          onTap: _hideFeedbackPanel,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 600,
                  ),
                  child: RepaintBoundary(
                    key: _screenshotKey,
                    child: FeedbackPanel(
                      screenshotKey: _screenshotKey,
                      onSubmit: (feedback, screenshot) {
                        widget.onFeedbackSubmitted(feedback, screenshot);
                        _hideFeedbackPanel();
                      },
                      onClose: _hideFeedbackPanel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideFeedbackPanel() {
    if (!_showFeedbackPanel) return;

    setState(() => _showFeedbackPanel = false);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}
