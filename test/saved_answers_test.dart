import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/customer/ai_assistant/saved_answers.dart';

void main() {
  test(
    'saved tips cover the five starter questions without invented live data',
    () {
      expect(
        savedAssistantAnswer('Which fruits are rich in Vitamin C?'),
        contains('kiwi'),
      );
      expect(
        savedAssistantAnswer('How should tomatoes be stored?'),
        contains('Refrigerate cut tomatoes'),
      );
      expect(
        savedAssistantAnswer('Which vegetables are seasonal right now?'),
        contains('cannot verify'),
      );
      expect(
        savedAssistantAnswer('What are the health benefits of spinach?'),
        contains('Spinach'),
      );
      expect(
        savedAssistantAnswer('Suggest vegetables for a healthy salad.'),
        contains('chickpeas'),
      );
      expect(
        savedAssistantAnswer('What does a dragon fruit cost today?'),
        contains('cannot check live prices'),
      );
    },
  );
}
