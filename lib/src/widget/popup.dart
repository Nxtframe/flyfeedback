import 'package:flutter/material.dart';

/// Callback type for popup events
typedef PopupCallback = void Function();

/// Builder function type for popup content
typedef PopupBuilder =
    Widget Function(BuildContext context, PopupController controller);

/// Controller for managing popup state and behavior
class PopupController extends ChangeNotifier {
  bool _isOpen = false;
  bool get isOpen => _isOpen;

  /// Opens the popup if it's not already open
  void open() {
    if (!_isOpen) {
      _isOpen = true;
      notifyListeners();
    }
  }

  /// Closes the popup if it's open
  void close() {
    if (_isOpen) {
      _isOpen = false;
      notifyListeners();
    }
  }

  /// Toggles the popup's open/closed state
  void toggle() {
    _isOpen ? close() : open();
  }
}

/// The state class for the Popup widget
class PopupState extends State<Popup> with TickerProviderStateMixin {
  late final PopupController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PopupController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );

    // Sync the animation with the controller state
    _controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(Popup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_handleControllerChange);
      _controller = widget.controller ?? PopupController();
      _controller.addListener(_handleControllerChange);
    }
  }

  void _handleControllerChange() {
    if (_controller.isOpen) {
      _animationController.forward().then((_) {
        widget.onOpened?.call();
      });
    } else {
      _animationController.reverse().then((_) {
        widget.onClosed?.call();
      });
    }
  }

  /// Shows the popup
  void show() {
    _controller.open();
  }

  /// Hides the popup
  void hide() {
    _controller.close();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    // Only dispose the controller if it was created by this widget
    if (widget.controller == null) {
      _controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The child that triggers the popup
        widget.child,
        
        // The popup overlay
        if (_controller.isOpen)
          GestureDetector(
            onTap: widget.dismissible ? () => _controller.close() : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: widget.barrierColor ?? Colors.black54,
              child: Center(
                child: ScaleTransition(
                  scale: _animation,
                  child: Material(
                    color: widget.backgroundColor,
                    elevation: widget.elevation ?? 8.0,
                    shape: widget.shape,
                    clipBehavior: widget.clipBehavior,
                    child: widget.builder(context, _controller),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A customizable popup widget that can be triggered by any widget
class Popup extends StatefulWidget {
  /// The key that can be used to control this popup
  final GlobalKey<PopupState>? key;
  /// Builder function that returns the popup content
  final PopupBuilder builder;

  /// The widget that will trigger the popup when tapped
  final Widget child;

  /// Optional controller to manage the popup state externally
  final PopupController? controller;

  /// Whether the popup can be dismissed by tapping outside
  final bool dismissible;

  /// Background color of the popup barrier
  final Color? barrierColor;

  /// Duration of the show/hide animation
  final Duration animationDuration;

  /// Animation curve for the show/hide animation
  final Curve animationCurve;

  /// Callback when the popup is opened
  final PopupCallback? onOpened;

  /// Callback when the popup is closed
  final PopupCallback? onClosed;

  /// Background color of the popup
  final Color? backgroundColor;

  /// Elevation of the popup
  final double? elevation;

  /// Shape of the popup
  final ShapeBorder? shape;

  /// Clip behavior of the popup
  final Clip clipBehavior;

  const Popup({
    this.key,
    required this.builder,
    required this.child,
    this.controller,
    this.dismissible = true,
    this.barrierColor,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.onOpened,
    this.onClosed,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior = Clip.none,
  }) : super(key: key);

  @override
  _PopupState createState() => _PopupState();
}

class _PopupState extends State<Popup> with SingleTickerProviderStateMixin {
  late final PopupController _controller;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PopupController();
    _controller.addListener(_handlePopupStateChange);

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.removeListener(_handlePopupStateChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handlePopupStateChange() {
    if (_controller.isOpen) {
      _showPopup();
      widget.onOpened?.call();
    } else {
      _animationController.reverse().then((_) => widget.onClosed?.call());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _controller.toggle(),
      child: widget.child,
    );
  }

  void _showPopup() {
    if (!_controller.isOpen) return;

    showDialog(
      context: context,
      barrierDismissible: widget.dismissible,
      barrierColor: widget.barrierColor ?? Colors.black54,
      builder: (context) => _buildPopup(),
    );
  }

  Widget _buildPopup() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(_animation),
            child: Material(
              color: widget.backgroundColor ?? Theme.of(context).cardColor,
              elevation: widget.elevation ?? 8.0,
              shape:
                  widget.shape ??
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
              clipBehavior: widget.clipBehavior,
              child: widget.builder(context, _controller),
            ),
          ),
        );
      },
    );
  }
}
