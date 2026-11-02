part of '../customer.dart';

Future<void> toggleFarmFollow(BuildContext context, Farm farm) async {
  final store = HarvestScope.of(context);
  final error = await store.toggleFollowed(farm.id);
  if (!context.mounted) return;
  notice(
    context,
    error ??
        (store.isFollowed(farm.id)
            ? 'Following ${farm.name}.'
            : 'Unfollowed ${farm.name}.'),
    isError: error != null,
  );
}
