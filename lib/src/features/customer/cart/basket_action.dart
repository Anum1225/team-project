part of '../customer.dart';

class BasketAction extends StatelessWidget {
  const BasketAction({super.key, this.floating = false});
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.role != UserRole.customer) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Your basket',
      style: floating
          ? IconButton.styleFrom(
              fixedSize: const Size(70, 70),
              backgroundColor: Harvest.colors(context).forest,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x55305236),
            )
          : null,
      onPressed: () => openPage(context, const BasketScreen()),
      icon: Badge(
        isLabelVisible: store.basketCount > 0,
        label: Text(
          '${store.basketCount}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Harvest.forest,
        child: Icon(Icons.shopping_bag_outlined, size: floating ? 28 : 22),
      ),
    );
  }
}
