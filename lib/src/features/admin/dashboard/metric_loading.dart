part of '../../common/reports/reporting.dart';

class _MetricLoading extends StatefulWidget {
  const _MetricLoading({this.width = 80});
  final double width;
  @override
  State<_MetricLoading> createState() => _MetricLoadingState();
}

class _MetricLoadingState extends State<_MetricLoading>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading metric',
    child: SizedBox(
      height: 32,
      width: widget.width,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FadeTransition(
          opacity: Tween(begin: .35, end: .8).animate(_pulse),
          child: Container(
            height: 22,
            decoration: BoxDecoration(
              color: Harvest.colors(context).green.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
      ),
    ),
  );
}
