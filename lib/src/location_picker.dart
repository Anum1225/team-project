import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

class LocationPickerButton extends StatelessWidget {
  const LocationPickerButton({super.key, required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Choose location on map',
    onPressed: () async {
      FocusScope.of(context).unfocus();
      final result = await showModalBottomSheet<LatLng>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        backgroundColor: Harvest.colors(context).surface,
        builder: (_) => const _LocationSheet(),
      );
      if (result != null) {
        onSelected(
          '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}',
        );
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
  LatLng? selected;
  bool locating = false;
  String? error;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> locate() async {
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
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      controller.move(point, 16);
      setState(() => selected = point);
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
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Padding(
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
              'Tap the map or move it beneath the pin. You can also type your address in the form.',
              style: TextStyle(color: colors.muted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 12),
            Expanded(
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
                          setState(() {
                            selected = point;
                            error = null;
                          });
                        },
                        onPositionChanged: (camera, gesture) {
                          if (gesture) setState(() => selected = camera.center);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.harvesthub.app',
                          maxNativeZoom: 19,
                          errorTileCallback: (_, _, _) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && error == null) {
                                setState(
                                  () => error =
                                      'Map tiles could not load. Check your connection, or close the map and type your address.',
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
                  : '${selected!.latitude.toStringAsFixed(5)}, ${selected!.longitude.toStringAsFixed(5)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error!,
                  style: const TextStyle(color: Harvest.danger, fontSize: 12),
                ),
              ),
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
                locating ? 'Finding your location…' : 'Auto-detect my location',
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: selected == null || locating
                  ? null
                  : () => Navigator.pop(context, selected),
              child: const Text('Use this location'),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}
