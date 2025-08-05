import 'package:flutter/material.dart';
import 'package:flyfeedback/flyfeedback.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feedback Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FeedbackWrapper(
        onFeedbackSubmitted: (feedback, screenshot) {
          // In a real app, you would send this to your server
          developer.log('Feedback submitted: $feedback');
          if (screenshot != null) {
            developer.log('Screenshot size: ${screenshot.length} bytes');
          }
          
          // Show a success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you for your feedback!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: const FeedbackDemo(),
      ),
    );
  }
}

class FeedbackDemo extends StatelessWidget {
  const FeedbackDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return FeedbackWrapper(
      onFeedbackSubmitted: (String feedback, Uint8List? screenshot) async {
        // Here you would typically send the feedback to your server
        debugPrint('Feedback submitted: $feedback');
        if (screenshot != null) {
          debugPrint('Screenshot size: ${screenshot.length} bytes');
        }
        
        // Show a success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thank you for your feedback!')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Feedback Demo'),
          actions: [
            IconButton(
              icon: const Icon(Icons.feedback),
              onPressed: () {
                // Get the FeedbackWrapperState and show the feedback panel
                final feedbackState = FeedbackWrapper.of(context);
                feedbackState?.showFeedbackPanel();
              },
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to the Feedback Demo!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text('Tap the feedback button in the app bar to report an issue.'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            void _showFeedback() {
              // Get the FeedbackWrapper state and show the feedback panel
              final feedbackState = FeedbackWrapper.of(context);
              if (feedbackState != null) {
                feedbackState.showFeedbackPanel();
              } else {
                // Fallback in case the widget tree doesn't have a FeedbackWrapper
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Feedback System Not Initialized'),
                    content: const Text('Please ensure your app is wrapped with FeedbackWrapper.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            }
            _showFeedback();
          },
          child: const Icon(Icons.feedback),
        ),
      ),
    );
  }
}
