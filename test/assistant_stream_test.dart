import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/customer/ai_assistant/assistant.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/customer/ai_assistant/gemini_assistant.dart';

import 'fixtures/preview_store.dart';

import 'package:untitled/src/features/common/data/store.dart';
import 'package:untitled/src/features/common/shared/theme.dart';

class ControlledAssistant extends GeminiAssistant {
  final responses = <StreamController<String>>[];
  final histories = <List<ChatMessage>>[];
  @override
  Stream<String> answer(List<ChatMessage> history, HarvestStore store) {
    final response = StreamController<String>();
    histories.add(List.of(history));
    responses.add(response);
    return response.stream;
  }
}

void main() {
  testWidgets(
    'chat streams real chunks, clears old streams, and retries failures',
    (tester) async {
      final service = ControlledAssistant();
      final store = PreviewStore();
      await tester.pumpWidget(
        HarvestScope(
          store: store,
          child: MaterialApp(
            theme: Harvest.theme,
            home: AssistantScreen(assistant: service),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('How should tomatoes be stored?'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('How should tomatoes be stored?'));
      await tester.pump();
      expect(service.responses.length, 1);
      service.responses.first.add('A streamed answer');
      await tester.pump();
      expect(find.textContaining('A streamed answer'), findsWidgets);
      expect(find.text('SAVED ANSWER'), findsNothing);
      await tester.tap(find.byTooltip('New conversation'));
      await tester.pump();
      service.responses.first.add(' stale response');
      await tester.pump();
      expect(find.textContaining('stale response'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('How should tomatoes be stored?'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('How should tomatoes be stored?'));
      await tester.pump();
      service.responses.last.addError(StateError('network unavailable'));
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('SAVED ANSWER'), findsOneWidget);
      expect(find.textContaining('Refrigerate cut tomatoes'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(service.responses.length, 3);
      expect(find.text('SAVED ANSWER'), findsNothing);
      expect(service.histories.last.length, 1);
      service.responses.last.add('Recovered answer');
      await tester.pump();
      unawaited(service.responses.last.close());
      await tester.pump();
      expect(find.textContaining('Recovered answer'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
}
