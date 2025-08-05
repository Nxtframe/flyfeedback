import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../utils/drawing_utils.dart';

class FeedbackPanel extends StatefulWidget {
  final GlobalKey screenshotKey;
  final Function(String, Uint8List?) onSubmit;
  final VoidCallback onClose;

  const FeedbackPanel({
    super.key,
    required this.screenshotKey,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  _FeedbackPanelState createState() => _FeedbackPanelState();
}

class _FeedbackPanelState extends State<FeedbackPanel> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  Uint8List? _screenshotBytes;
  bool _isSubmitting = false;

  // Drawing state
  DrawingMode _currentMode = DrawingMode.pen;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  final List<DrawingArea> _drawingHistory = [];
  final List<DrawingArea> _redoHistory = [];
  final List<DrawingPoint> _points = [];
  Offset? _textPosition;
  bool _isAddingText = false;

  @override
  void initState() {
    super.initState();
    _captureScreenshot();
  }

  Future<void> _captureScreenshot() async {
    try {
      final boundary =
          widget.screenshotKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (bytes != null) {
        setState(() {
          _screenshotBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
    }
  }

  // No-op since we're keeping the screenshot in memory
  void _onScreenshotCaptured() {
    if (_screenshotBytes != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screenshot captured for feedback'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your feedback')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // If we have a screenshot, capture the current state with drawings
    if (_screenshotBytes != null) {
      try {
        final boundary =
            widget.screenshotKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 3.0);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final bytes = byteData?.buffer.asUint8List();

          if (bytes != null) {
            widget.onSubmit(_feedbackController.text, bytes);
            return;
          }
        }
      } catch (e) {
        debugPrint('Error capturing final screenshot: $e');
      }
    }

    // Fallback to original screenshot if capture fails
    widget.onSubmit(_feedbackController.text, _screenshotBytes);
  }

  // Drawing methods
  void _onPanStart(DragStartDetails details) {
    if (_currentMode != DrawingMode.pen && _currentMode != DrawingMode.erase)
      return;

    setState(() {
      _points.add(
        DrawingPoint(
          point: details.localPosition,
          paint: Paint()
            ..color = _currentMode == DrawingMode.erase
                ? Colors.white
                : _selectedColor.withAlpha(255)
            ..strokeWidth = _currentMode == DrawingMode.erase
                ? 20.0
                : _strokeWidth
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..strokeJoin = StrokeJoin.round,
          isErase: _currentMode == DrawingMode.erase,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentMode != DrawingMode.pen && _currentMode != DrawingMode.erase)
      return;

    setState(() {
      _points.add(
        DrawingPoint(
          point: details.localPosition,
          paint: Paint()
            ..color = _currentMode == DrawingMode.erase
                ? Colors.white
                : _selectedColor.withOpacity(1.0)
            ..strokeWidth = _currentMode == DrawingMode.erase
                ? 20.0
                : _strokeWidth
            ..strokeCap = StrokeCap.round
            ..isAntiAlias = true
            ..strokeJoin = StrokeJoin.round,
          isErase: _currentMode == DrawingMode.erase,
        ),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_points.isEmpty) return;

    setState(() {
      _drawingHistory.add(DrawingArea(points: List.from(_points)));
      _points.clear();
      _redoHistory.clear();
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (_currentMode == DrawingMode.text) {
      setState(() {
        _textPosition = details.localPosition;
        _isAddingText = true;
      });
    }
  }

  void _addText() {
    if (_textController.text.isEmpty || _textPosition == null) {
      setState(() => _isAddingText = false);
      return;
    }

    setState(() {
      _drawingHistory.add(
        DrawingArea(
          points: [],
          textPosition: _textPosition!,
          text: _textController.text,
          textStyle: TextStyle(
            color: _selectedColor,
            fontSize: _strokeWidth * 5 + 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      _textController.clear();
      _isAddingText = false;
      _redoHistory.clear();
    });
  }

  void _undo() {
    if (_drawingHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(_drawingHistory.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _drawingHistory.add(_redoHistory.removeLast());
      });
    }
  }

  void _clearAll() {
    setState(() {
      _drawingHistory.clear();
      _redoHistory.clear();
      _points.clear();
    });
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        margin: const EdgeInsets.all(2),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    bool isSelected = false,
  }) {
    return IconButton(
      icon: Icon(icon, color: isSelected ? Colors.blue : null),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Send Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Screenshot with Drawing Canvas
          if (_screenshotBytes != null) ...[
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.memory(
                        _screenshotBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Drawing Canvas
                    GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onTapDown: _onTapDown,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: DrawingPainter(
                          points: _points,
                          drawingHistory: _drawingHistory,
                        ),
                      ),
                    ),
                    // Text Annotations
                    ..._drawingHistory.where((area) => area.text != null).map((
                      area,
                    ) {
                      return Positioned(
                        left: area.textPosition?.dx,
                        top: area.textPosition?.dy,
                        child: Text(area.text!, style: area.textStyle),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Toolbar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildToolButton(
                    Icons.brush,
                    'Pen',
                    () => setState(() => _currentMode = DrawingMode.pen),
                    isSelected: _currentMode == DrawingMode.pen,
                  ),
                  _buildToolButton(
                    Icons.text_fields,
                    'Add Text',
                    () => setState(() => _currentMode = DrawingMode.text),
                    isSelected: _currentMode == DrawingMode.text,
                  ),
                  _buildToolButton(
                    Icons.auto_fix_normal,
                    'Eraser',
                    () => setState(() => _currentMode = DrawingMode.erase),
                    isSelected: _currentMode == DrawingMode.erase,
                  ),
                  _buildToolButton(Icons.undo, 'Undo', _undo),
                  _buildToolButton(Icons.redo, 'Redo', _redo),
                  _buildToolButton(Icons.clear, 'Clear All', _clearAll),
                ],
              ),
            ),
            // Color Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorButton(Colors.red),
                _buildColorButton(Colors.blue),
                _buildColorButton(Colors.green),
                _buildColorButton(Colors.black),
                _buildColorButton(Colors.yellow),
              ],
            ),
            // Stroke Width Slider
            Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              onChanged: (value) => setState(() => _strokeWidth = value),
              label: 'Stroke Width: ${_strokeWidth.toStringAsFixed(0)}',
            ),
            // Text Input Dialog
            if (_isAddingText) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Enter text',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: _addText,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _isAddingText = false),
                      ),
                    ],
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) => _addText(),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Feedback Input
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Describe your feedback or issue...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit Feedback',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _textController.dispose();
    super.dispose();
  }
}
