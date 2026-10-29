part of '../../common/profile/profile.dart';

class FarmEditorScreen extends StatefulWidget {
  const FarmEditorScreen({super.key, this.farm});
  final Farm? farm;
  @override
  State<FarmEditorScreen> createState() => _FarmEditorScreenState();
}

class _FarmEditorScreenState extends State<FarmEditorScreen> {
  Uint8List? _banner;
  bool _pickingBanner = false;

  Future<void> _pickBanner() async {
    setState(() => _pickingBanner = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (file == null) return;
      if (await file.length() > 8 * 1024 * 1024) {
        if (mounted) {
          notice(context, 'Choose an image smaller than 8 MB.', isError: true);
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _banner = bytes);
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not open the image. Please check photo access.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pickingBanner = false);
    }
  }

  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      location = TextEditingController(),
      market = TextEditingController(),
      description = TextEditingController(),
      windows = TextEditingController();
  double? selectedLatitude, selectedLongitude;
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final f = widget.farm ?? HarvestScope.of(context).ownFarm;
    name.text = f.name;
    location.text = f.location;
    selectedLatitude = f.latitude;
    selectedLongitude = f.longitude;
    market.text = f.market;
    description.text = f.description;
    windows.text = f.pickupSlots.join("\n");
  }

  @override
  void dispose() {
    for (final c in [name, location, market, description, windows]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return HarvestPage(
      title: 'Your farm profile',
      bottom: HarvestButton(
        label: 'Save farm profile',
        onPressed: store.busy || _pickingBanner
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                final original = widget.farm ?? store.ownFarm;
                final f = Farm(
                  id: original.id,
                  owner: original.owner,
                  name: name.text.trim(),
                  location: location.text.trim(),
                  market: market.text.trim(),
                  description: description.text.trim(),
                  image: original.image,
                  photo: _banner,
                  pickupSlots: windows.text
                      .split('\n')
                      .map((v) => v.trim())
                      .where((v) => v.isNotEmpty)
                      .toSet()
                      .toList(),
                  latitude: selectedLatitude,
                  longitude: selectedLongitude,
                  active: original.active,
                );
                final result = await store.saveFarm(f);
                if (!context.mounted) return;
                if (result != null) {
                  notice(context, result, isError: true);
                  return;
                }
                Navigator.pop(context);
                notice(context, 'Farm profile updated');
              },
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Photo(
              (widget.farm ?? store.ownFarm).image,
              bytes: _banner,
              height: 180,
              width: double.infinity,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickingBanner || store.busy ? null : _pickBanner,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _pickingBanner ? 'Opening photos…' : 'Change farm banner',
              ),
            ),
            if (_banner != null)
              TextButton(
                onPressed: () => setState(() => _banner = null),
                child: const Text('Undo selected image'),
              ),
            const PageHeading('Tell your\nfarm’s story.'),
            HarvestField(controller: name, label: 'Farm or business name'),
            const SizedBox(height: 16),
            HarvestField(controller: location, label: 'Location'),
            Align(
              alignment: Alignment.centerRight,
              child: LocationPickerButton(
                onLocationSelected: (value) => setState(() {
                  location.text = value.address;
                  selectedLatitude = value.latitude;
                  selectedLongitude = value.longitude;
                }),
              ),
            ),
            HarvestField(
              controller: windows,
              label: 'Pickup windows (one per line, up to 20)',
              lines: 5,
              validator: (value) {
                final rows = (value ?? '')
                    .split('\n')
                    .where((s) => s.trim().isNotEmpty);
                return rows.length > 20 || rows.any((s) => s.length > 160)
                    ? 'Use up to 20 windows, each under 160 characters.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            HarvestField(controller: market, label: 'Market name'),
            const SizedBox(height: 16),
            HarvestField(
              controller: description,
              label: 'About your farm',
              lines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
