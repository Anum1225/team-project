import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Android speech recognizer bridge with an in-app listening animation.
class VoiceSearchControl extends StatefulWidget {
  const VoiceSearchControl({super.key, required this.onText});
  final ValueChanged<String> onText;

  @override
  State<VoiceSearchControl> createState() => _VoiceSearchControlState();
}

class _VoiceSearchControlState extends State<VoiceSearchControl>
    with SingleTickerProviderStateMixin {
  static const _channel = MethodChannel('harvesthub/voice_search');
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );
  bool _listening = false;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_listening) return;
    HapticFeedback.selectionClick();
    setState(() => _listening = true);
    _pulse.repeat(reverse: true);
    try {
      final value = await _channel.invokeMethod<String>('listen');
      final result = value?.trim() ?? '';
      if (result.isNotEmpty) widget.onText(result);
    } on PlatformException catch (e) {
      if (mounted) {
        _message(
          e.message ?? 'Voice search could not start. Check microphone access.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        _message('Voice search is available on Android devices.');
      }
    } finally {
      _pulse.stop();
      if (mounted) setState(() => _listening = false);
    }
  }

  void _message(String message) {
    final palette = Harvest.colors(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: palette.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: _listening ? 'Listening…' : 'Search by voice',
    child: IconButton(
      onPressed: _start,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 44),
      icon: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: _listening ? 1 + _pulse.value * .12 : 1,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening
                  ? Harvest.colors(
                      context,
                    ).green.withValues(alpha: .14 + .1 * _pulse.value)
                  : Colors.transparent,
              border: _listening
                  ? Border.all(
                      color: Harvest.colors(
                        context,
                      ).green.withValues(alpha: .28),
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: Icon(
              _listening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
              size: 20,
              color: _listening
                  ? Harvest.colors(context).green
                  : Harvest.colors(context).muted,
            ),
          ),
        ),
      ),
    ),
  );
}
