library;

export 'src/widget/popup.dart';
export 'src/services/feedback_service.dart';
export 'src/widget/feedback_panel.dart';
export 'src/widget/feedback_wrapper.dart';

// Re-export important classes
export 'src/widget/popup.dart'
    show Popup, PopupController, PopupCallback, PopupBuilder;
export 'src/services/feedback_service.dart'
    show FeedbackService, feedbackService;
export 'src/widget/feedback_wrapper.dart' show FeedbackWrapper;
