import 'package:flutter/material.dart';
import '../widget/popup.dart' show Popup, PopupBuilder, PopupController;

/// A hook for showing popups with a simple function call
class PopUp {
  static final Map<String, PopupWithHookState> _popupInstances = {};

  /// Registers a popup with a unique key
  static void register(String key, PopupWithHookState instance) {
    _popupInstances[key] = instance;
  }

  /// Unregisters a popup
  static void unregister(String key) {
    _popupInstances.remove(key);
  }

  /// Shows a popup by its key
  static void show(String key) {
    if (_popupInstances.containsKey(key)) {
      _popupInstances[key]!.show();
    } else {
      debugPrint('No popup registered with key: $key');
    }
  }

  /// Hides a popup by its key
  static void hide(String key) {
    _popupInstances[key]?.hide();
  }
}

/// A stateful widget that can be controlled by the PopUp hook
class PopupWithHook extends StatefulWidget {
  final String popupKey;
  final Widget child;
  final PopupBuilder builder;
  final bool dismissible;
  final Color? barrierColor;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback? onOpened;
  final VoidCallback? onClosed;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip clipBehavior;

  const PopupWithHook({
    super.key,
    required this.popupKey,
    required this.child,
    required this.builder,
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
  });

  @override
  State<PopupWithHook> createState() => PopupWithHookState();
}

class PopupWithHookState extends State<PopupWithHook> {
  late final PopupController _controller = PopupController();

  @override
  void initState() {
    super.initState();
    // Register this popup when it's created
    PopUp.register(widget.popupKey, this);
  }

  @override
  void dispose() {
    // Unregister this popup when it's disposed
    PopUp.unregister(widget.popupKey);
    _controller.dispose();
    super.dispose();
  }

  void show() {
    _controller.open();
  }

  void hide() {
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return Popup(
      controller: _controller,
      builder: widget.builder,
      dismissible: widget.dismissible,
      barrierColor: widget.barrierColor,
      animationDuration: widget.animationDuration,
      animationCurve: widget.animationCurve,
      onOpened: widget.onOpened,
      onClosed: widget.onClosed,
      backgroundColor: widget.backgroundColor,
      elevation: widget.elevation,
      shape: widget.shape,
      clipBehavior: widget.clipBehavior,
      child: widget.child,
    );
  }
}
