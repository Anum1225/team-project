import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/assistant.dart';
import 'package:untitled/src/components.dart';
import 'package:untitled/src/gemini_assistant.dart';
import 'package:untitled/src/preview_store.dart';
import 'package:untitled/src/store.dart';
import 'package:untitled/src/theme.dart';

class ControlledAssistant extends GeminiAssistant {
  final responses = <StreamController<String>>[];
  @override
  Stream<String> answer(List<ChatMessage> history, HarvestStore store) {
    final response = StreamController<String>();
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
      await tester.ensureVisible(find.text('How should tomatoes be stored?'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('How should tomatoes be stored?'));
      await tester.pump();
      expect(service.responses.length, 1);
      service.responses.first.add('A streamed answer');
      await tester.pump();
      expect(find.textContaining('A streamed answer'), findsWidgets);
      await tester.tap(find.byTooltip('New conversation'));
      await tester.pump();
      service.responses.first.add(' stale response');
      await tester.pump();
      expect(find.textContaining('stale response'), findsNothing);
      await tester.ensureVisible(find.text('How should tomatoes be stored?'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('How should tomatoes be stored?'));
      await tester.pump();
      service.responses.last.addError(StateError('network unavailable'));
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(service.responses.length, 3);
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
