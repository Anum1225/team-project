import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/theme.dart';
import 'place_lookup.dart';
import 'place_resolver.dart';

export 'place_resolver.dart' show SelectedLocation;

class LocationPickerButton extends StatelessWidget {
  const LocationPickerButton({
    super.key,
    this.onSelected,
    this.onLocationSelected,
  }) : assert(onSelected != null || onLocationSelected != null);
  final ValueChanged<String>? onSelected;
  final ValueChanged<SelectedLocation>? onLocationSelected;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Choose location on map',
    onPressed: () async {
      FocusScope.of(context).unfocus();
      final result = await showModalBottomSheet<SelectedLocation>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Harvest.colors(context).surface,
        builder: (_) => const _LocationSheet(),
      );
      if (result != null && context.mounted) {
        onSelected?.call(result.address);
        onLocationSelected?.call(result);
      }
    },
    icon: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Harvest.colors(context).paleLeaf,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Harvest.colors(context).green.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(
        Icons.map_outlined,
        size: 21,
        color: Harvest.colors(context).green,
      ),
    ),
  );
}

class _LocationSheet extends StatefulWidget {
  const _LocationSheet();
  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final controller = MapController();
  final lookup = PlaceLookup();
  late final resolver = PlaceResolver(lookup.call);
  final manualAddress = TextEditingController();
  LatLng? selected;
  bool locating = false;
  String? error;
  int _pinRevision = 0;
  bool _manualEdited = false;

  @override
  void initState() {
    super.initState();
    resolver.addListener(_placeChanged);
  }

  void _placeChanged() {
    if (mounted) {
      if (!_manualEdited &&
          resolver.address != null &&
          manualAddress.text != resolver.address) {
        manualAddress.text = resolver.address!;
      }
      setState(() {});
    }
  }

  void selectPoint(LatLng point) {
    ++_pinRevision;
    selected = point;
    _manualEdited = false;
    manualAddress.clear();
    resolver.select(point.latitude, point.longitude);
  }

  @override
  void dispose() {
    controller.dispose();
    resolver.dispose();
    lookup.close();
    manualAddress.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    final pinRevision = _pinRevision;
    setState(() {
      locating = true;
      error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(
          'Turn on location services, or select a point on the map.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is unavailable. You can still tap the map or type your address.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted || pinRevision != _pinRevision) return;
      final point = LatLng(position.latitude, position.longitude);
      controller.move(point, 16);
      selectPoint(point);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is Exception && e.toString().startsWith('Exception: ')
              ? e.toString().substring(11)
              : 'Could not detect your location. Select a point or enter your address manually.',
        );
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Harvest.colors(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height:
            (MediaQuery.sizeOf(context).height * 0.86 -
                    MediaQuery.viewInsetsOf(context).bottom)
                .clamp(120.0, double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pin your location',
                      style: Harvest.editorial(25, color: colors.ink),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close map',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                'Move the map beneath the pin, then check or edit the address. Place lookup uses your device and OpenStreetMap.',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: (MediaQuery.sizeOf(context).height * 0.38).clamp(
                  200.0,
                  400.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: controller,
                        options: MapOptions(
                          initialCenter: const LatLng(24.8607, 67.0011),
                          initialZoom: 11,
                          maxZoom: 19,
                          onTap: (_, point) {
                            controller.move(point, controller.camera.zoom);
                            error = null;
                            selectPoint(point);
                          },
                          onPositionChanged: (camera, gesture) {
                            if (gesture) selectPoint(camera.center);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.untitled',
                            maxNativeZoom: 19,
                            errorTileCallback: (_, _, _) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && error == null) {
                                  setState(
                                    () => error = 'Map tiles could not load. Check your connection, or close the map and type your address.',
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -19),
                            child: Icon(
                              Icons.location_pin,
                              color: colors.green,
                              size: 44,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF173B29),
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
              const SizedBox(height: 10),
              Text(
                selected == null
                    ? 'Map starts in Karachi. Select your own location.'
                    : resolver.resolving
                    ? 'Finding this place’s address…'
                    : resolver.address ?? 'Place name unavailable',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
              if (error != null || resolver.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error ?? resolver.error!,
                    style: const TextStyle(color: Harvest.danger, fontSize: 12),
                  ),
                ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: manualAddress,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (value) {
                    _manualEdited = true;
                    resolver.useManualAddress(value);
                  },
                  onSubmitted: resolver.useManualAddress,
                  decoration: InputDecoration(
                    labelText: 'Place or street address',
                    counterText: '',
                    suffixIcon: IconButton(
                      tooltip: 'Use typed address with this pin',
                      onPressed: () =>
                          resolver.useManualAddress(manualAddress.text),
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: resolver.retry,
                  child: const Text('Retry place lookup'),
                ),
              ],
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: locating ? null : locate,
                icon: locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  locating
                      ? 'Finding your location…'
                      : 'Auto-detect my location',
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed:
                    resolver.selection == null || locating || resolver.resolving
                    ? null
                    : () => Navigator.pop(context, resolver.selection),
                child: const Text('Use this location'),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}
