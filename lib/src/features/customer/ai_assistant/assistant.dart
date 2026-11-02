import 'dart:async';

import 'gemini_assistant.dart';
import 'saved_answers.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/shared/components.dart';
import '../../common/shared/theme.dart';
import 'assistant_robot.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, this.assistant});
  final GeminiAssistant? assistant;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with TickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<({bool user, String text, bool isTyping, bool saved})> _messages =
      [];
  bool _isThinking = false;
  bool _isWriting = false;
  StreamSubscription<String>? _response;
  String? _chatError;
  int _conversationGeneration = 0;

  late final AnimationController _dotController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  static final List<String> _prompts = [
    'Which fruits are rich in Vitamin C?',
    'How should tomatoes be stored?',
    'Which vegetables are seasonal right now?',
    'What are the health benefits of spinach?',
    'Suggest vegetables for a healthy salad.',
  ];

  @override
  void dispose() {
    _response?.cancel();
    _input.dispose();
    _scroll.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _send(String text, {bool retry = false}) {
    final value = text.trim();
    if (value.isEmpty || _isThinking || _isWriting) return;
    final store = HarvestScope.of(context);
    HapticFeedback.lightImpact();
    setState(() {
      if (retry && _messages.isNotEmpty && _messages.last.saved) {
        _messages.removeLast();
      }
      if (!retry) {
        _messages.add((user: true, text: value, isTyping: false, saved: false));
      }
      _input.clear();
      _chatError = null;
      _isThinking = true;
    });
    final generation = ++_conversationGeneration;
    final history = _messages
        .where((m) => !m.saved)
        .map((m) => (user: m.user, text: m.text))
        .toList();
    var answer = '';
    int? answerIndex;
    _response = (widget.assistant ?? GeminiAssistant())
        .answer(history, store)
        .listen(
          (chunk) {
            if (!mounted || generation != _conversationGeneration) return;
            setState(() {
              _isThinking = false;
              _isWriting = true;
              answer += chunk;
              if (answerIndex == null) {
                answerIndex = _messages.length;
                _messages.add((
                  user: false,
                  text: answer,
                  isTyping: true,
                  saved: false,
                ));
              } else {
                _messages[answerIndex!] = (
                  user: false,
                  text: answer,
                  isTyping: true,
                  saved: false,
                );
              }
            });
            _scrollToBottom();
          },
          onError: (Object error) {
            if (!mounted || generation != _conversationGeneration) return;
            setState(() {
              _isThinking = false;
              _isWriting = false;
              // A partial stream must not be passed to Gemini as a complete answer.
              if (answerIndex != null) _messages.removeAt(answerIndex!);
              answerIndex = null;
              _messages.add((
                user: false,
                text: savedAssistantAnswer(value),
                isTyping: false,
                saved: true,
              ));
              _chatError =
                  'AI is temporarily unavailable. Showing a saved answer.';
            });
            _scrollToBottom();
          },
          onDone: () {
            if (!mounted || generation != _conversationGeneration) return;
            setState(() {
              _isThinking = false;
              _isWriting = false;
              if (answerIndex != null) {
                _messages[answerIndex!] = (
                  user: false,
                  text: answer,
                  isTyping: false,
                  saved: false,
                );
              }
            });
          },
          cancelOnError: true,
        );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    final generation = _conversationGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          generation == _conversationGeneration &&
          _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Harvest.colors(context).canvas,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OlaMascot(size: 36, showShadow: false),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'HarvestHub assistant',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Harvest.colors(context).ink,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            tooltip: 'New conversation',
            onPressed: () => setState(() {
              _conversationGeneration++;
              _messages.clear();
              _isThinking = false;
              _isWriting = false;
              _response?.cancel();
              if (_scroll.hasClients) _scroll.jumpTo(0);
              _chatError = null;
            }),
            icon: const Icon(Icons.refresh, size: 20),
          )
        else
          const SizedBox(width: 12),
      ],
    ),
    body: _buildAdvisorView(),
  );

  Widget _buildAdvisorView() => Column(
    children: [
      if (_chatError != null)
        MaterialBanner(
          content: Text(_chatError!),
          actions: [
            TextButton(
              onPressed: () {
                final last = _messages.lastWhere((m) => m.user);
                _send(last.text, retry: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      Expanded(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (_messages.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'A little help from Ola',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Live answers from Gemini, with saved tips when it’s unavailable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Harvest.colors(context).muted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              const InfoNote(
                'Ask about fresh produce or the live catalog. AI answers can be mistaken; check farm details before ordering.',
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 24),
              Text(
                'Start a conversation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Harvest.colors(context).muted,
                ),
              ),
              const SizedBox(height: 10),
              for (final prompt in _prompts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Harvest.colors(context).surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _send(prompt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Harvest.colors(context).border,
                          ),
                          boxShadow: Harvest.cardShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Harvest.honey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                prompt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Harvest.colors(context).muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              for (final message in _messages)
                Align(
                  alignment: message.user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: message.user
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!message.user) ...[
                        Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.only(bottom: 14, right: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Harvest.forest, Color(0xFF4CAF50)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      Flexible(
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 14,
                            left: message.user ? 48 : 0,
                            right: message.user ? 0 : 48,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: message.user
                                ? Harvest.forest
                                : Harvest.colors(context).surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(
                                message.user ? 20 : 4,
                              ),
                              bottomRight: Radius.circular(
                                message.user ? 4 : 20,
                              ),
                            ),
                            border: Border.all(
                              color: message.user
                                  ? Colors.transparent
                                  : Harvest.colors(context).border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!message.user) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Harvest.colors(context).green
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 11,
                                            color: Harvest.colors(context)
                                                .green,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            message.saved
                                                ? 'SAVED ANSWER'
                                                : 'HARVEST GUIDE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.0,
                                              color: Harvest.colors(context)
                                                  .green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (message.isTyping) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8A93B)
                                              .withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'WRITING...',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                            color: Color(0xFFE8A93B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (message.text.isNotEmpty)
                                SelectableText(
                                  message.text,
                                  style: TextStyle(
                                    color: message.user
                                        ? Colors.white
                                        : Harvest.colors(context).ink,
                                    fontSize: 14,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              if (message.isTyping && message.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: AnimatedBuilder(
                                    animation: _dotController,
                                    builder: (context, _) => SizedBox(
                                      width: 8,
                                      height: 16,
                                      child: Opacity(
                                        opacity:
                                            (0.3 +
                                                    0.7 *
                                                        (0.5 +
                                                            0.5 *
                                                                ((_dotController.value *
                                                                            6.28)
                                                                        .remainder(
                                                                          6.28,
                                                                        ))
                                                                    .abs() /
                                                                3.14))
                                                .clamp(0.0, 1.0),
                                        child: Text(
                                          '▌',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Harvest.colors(context)
                                                .green,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Thinking indicator with animated bouncing dots
              if (_isThinking)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(bottom: 14, right: 8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Harvest.forest, Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Harvest.colors(context).surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(4),
                          ),
                          border: Border.all(
                            color: Harvest.colors(context).border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _dotController,
                          builder: (context, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < 3; i++) ...[
                                  if (i > 0) const SizedBox(width: 4),
                                  Transform.translate(
                                    offset: Offset(
                                      0,
                                      -4 *
                                          math
                                              .sin(
                                                (_dotController.value *
                                                        2 *
                                                        math.pi) -
                                                    (i * 0.65),
                                              )
                                              .abs(),
                                    ),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Harvest.colors(context).green
                                            .withValues(
                                              alpha:
                                                  0.45 +
                                                  0.55 *
                                                      math
                                                          .sin(
                                                            (_dotController
                                                                        .value *
                                                                    2 *
                                                                    math.pi) -
                                                                (i * 0.65),
                                                          )
                                                          .abs(),
                                            ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 10),
                                Text(
                                  'Thinking',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    color: Harvest.colors(context).muted,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),

      // Premium composer bar
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: Harvest.colors(context).surface,
          border: Border(
            top: BorderSide(color: Harvest.colors(context).border),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: 'Ask Ola a question…',
                    fillColor: Harvest.colors(context).cream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Harvest.forest,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Harvest.forest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _send(_input.text),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
