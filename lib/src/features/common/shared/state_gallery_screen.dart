part of '../profile/profile.dart';

class StateGalleryScreen extends StatefulWidget {
  const StateGalleryScreen({super.key});
  @override
  State<StateGalleryScreen> createState() => _StateGalleryScreenState();
}

class _StateGalleryScreenState extends State<StateGalleryScreen> {
  String state = 'Loading';
  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Interface states',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          'Care in every state.',
          subtitle: 'A design reference for future service integration.',
        ),
        ChoiceRow(
          values: const [
            'Loading',
            'Empty',
            'Offline',
            'Error',
            'Unauthorized',
          ],
          selected: state,
          onSelected: (v) => setState(() => state = v),
        ),
        const SizedBox(height: 28),
        if (state == 'Loading')
          Semantics(
            label: 'Loading products',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 90,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Harvest.colors(context).paleLeaf,
                            borderRadius: Harvest.radius,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 16,
                                color: Harvest.colors(context).border,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 12,
                                color: Harvest.colors(context).paleLeaf,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 12,
                                color: Harvest.colors(context).paleLeaf,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        else
          EmptyState(
            title: switch (state) {
              'Empty' => 'Save something fresh.',
              'Offline' => 'You’re offline.',
              'Unauthorized' => 'This space is protected.',
              _ => 'Something didn’t grow right.',
            },
            message: switch (state) {
              'Empty' =>
                'Browse seasonal produce to keep your favourites close.',
              'Offline' => 'We’ll reconnect when your network returns.',
              'Unauthorized' =>
                'Sign in with the right account to access this area.',
              _ => 'We couldn’t load your products. Please try again.',
            },
            icon: switch (state) {
              'Empty' => Icons.favorite_border,
              'Offline' => Icons.wifi_off,
              'Unauthorized' => Icons.lock_outline,
              _ => Icons.error_outline,
            },
            action: 'Reset preview',
            onAction: () => setState(() => state = 'Loading'),
          ),
      ],
    ),
  );
}
