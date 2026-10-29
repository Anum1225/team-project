part of '../authentication.dart';

class _AuthPhotoPanel extends StatelessWidget {
  const _AuthPhotoPanel({required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context) {
    final colors = Harvest.colors(context);
    final farmer = role == UserRole.farmer;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(role),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.paleLeaf,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(36),
              ),
              child: Image.asset(
                farmer
                    ? 'assets/images/farmer_holding_crate.jpg'
                    : role == UserRole.admin
                    ? 'assets/images/farm_hero_banner.jpg'
                    : 'assets/images/farm_produce_crate.jpg',
                width: 92,
                height: 96,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer
                        ? 'From your farm,\nto their table.'
                        : role == UserRole.admin
                        ? 'Your marketplace.\nIn good hands.'
                        : 'Good food.\nCloser to home.',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    farmer
                        ? 'Your growing community awaits.'
                        : role == UserRole.admin
                        ? 'Manage the HarvestHub community.'
                        : 'Welcome to your local harvest.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
