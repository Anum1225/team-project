export '../../admin/content/public_content_editor.dart'
    show PublicContentEditor;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../authentication/authentication.dart';
import '../shared/components.dart';
import '../location/location_picker.dart';
import '../data/models.dart';
import '../../customer/customer.dart' show FarmerTile;

/// Only administrator-approved markets appear in the public directory.
List<Map<String, dynamic>> marketListings(
  List<Map<String, dynamic>> published,
  List<Farm> farms, {
  bool admin = false,
  String? ownerId,
}) {
  String key(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return published
      .where((row) => (row['name'] as String? ?? '').trim().isNotEmpty)
      .where(
        (entry) =>
            admin ||
            (entry['active'] == true &&
                entry['approvalStatus'] != 'pending' &&
                entry['approvalStatus'] != 'rejected') ||
            (ownerId != null && entry['owner'] == ownerId),
      )
      .map(
        (entry) => <String, dynamic>{
          ...entry,
          'farms': farms
              .where(
                (f) =>
                    f.active && key(f.market) == key(entry['name'] as String),
              )
              .toList(),
        },
      )
      .toList()
    ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
}

class MarketDirectory extends StatelessWidget {
  const MarketDirectory({super.key});
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final admin = store.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmers markets'),
        actions: [
          if (admin || store.role == UserRole.farmer)
            IconButton(
              tooltip: 'Add market',
              icon: const Icon(Icons.add),
              onPressed: () => openPage(context, const MarketEditor()),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: !store.live
            ? null
            : FirebaseFirestore.instance
                  .collection('farmersMarkets')
                  .limit(200)
                  .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load markets. Please reopen this page.'),
            );
          }
          if (store.live && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = marketListings(
            [
              if (!store.live) ...store.publicMarkets,
              for (final doc
                  in snapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                {...doc.data(), 'id': doc.id},
            ],
            store.farms,
            admin: admin,
            ownerId: store.role == UserRole.farmer ? store.account.id : null,
          );
          if (rows.isEmpty) {
            return Center(
              child: Text(
                admin ? 'No markets yet. Tap + to publish a market.' : 'No markets listed yet. Farmers can submit a market for approval.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final d = rows[i];
              final farms = d['farms'] as List<Farm>;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d['name'] as String? ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if ((d['location'] as String? ?? '').isNotEmpty)
                        Text(d['location'] as String),
                      const SizedBox(height: 8),
                      Text(
                        (d['hours'] as String? ?? '').isNotEmpty
                            ? 'Hours: ${d['hours']}'
                            : 'Opening hours not published',
                      ),
                      if (d['farmProvided'] == true)
                        const Text('Listed by local farmers'),
                      if (d['approvalStatus'] == 'pending')
                        const Text('Awaiting administrator approval'),
                      if (d['approvalStatus'] == 'rejected')
                        const Text('Rejected by administrator'),
                      for (final farm in farms) FarmerTile(farm: farm),
                      if (d['lat'] != null && d['lng'] != null)
                        const Text('Map location saved'),
                      if (admin)
                        TextButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            d['active'] == true
                                ? 'Edit market'
                                : 'Edit inactive market',
                          ),
                          onPressed: () => openPage(
                            context,
                            MarketEditor(id: d['id'] as String?, data: d),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MarketEditor extends StatefulWidget {
  const MarketEditor({super.key, this.id, this.data = const {}});
  final String? id;
  final Map<String, dynamic> data;
  @override
  State<MarketEditor> createState() => _MarketEditorState();
}

class _MarketEditorState extends State<MarketEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.data['name'] as String? ?? '',
  );
  late final location = TextEditingController(
    text: widget.data['location'] as String? ?? '',
  );
  late final hours = TextEditingController(
    text: widget.data['hours'] as String? ?? '',
  );
  late bool active = widget.data['active'] as bool? ?? true;
  late double? latitude = (widget.data['lat'] as num?)?.toDouble(),
      longitude = (widget.data['lng'] as num?)?.toDouble();
  bool busy = false;
  @override
  void dispose() {
    name.dispose();
    location.dispose();
    hours.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (latitude == null || longitude == null) {
      notice(context, 'Choose the market position on the map.', isError: true);
      return;
    }
    setState(() => busy = true);
    try {
      final store = HarvestScope.of(context);
      final farmer = store.role == UserRole.farmer;
      final ref = FirebaseFirestore.instance
          .collection('farmersMarkets')
          .doc(widget.id);
      await ref.set({
        'name': name.text.trim(),
        'location': location.text.trim(),
        'hours': hours.text.trim(),
        'lat': latitude,
        'lng': longitude,
        'active': farmer ? false : active,
        if (farmer) 'owner': store.account.id,
        if (farmer) 'approvalStatus': 'pending',
        if (!farmer && widget.data['owner'] != null)
          'owner': widget.data['owner'],
        if (!farmer && widget.data['approvalStatus'] != null)
          'approvalStatus': widget.data['approvalStatus'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Market could not be saved. Retry when connected.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.id == null ? 'Add market' : 'Edit market'),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          HarvestField(controller: name, label: 'Market name'),
          const SizedBox(height: 16),
          HarvestField(controller: location, label: 'Address / location'),
          const SizedBox(height: 16),
          HarvestField(
            controller: hours,
            label: 'Operating days and hours',
            lines: 3,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              latitude == null ? 'Set map position' : 'Map position selected',
            ),
            trailing: LocationPickerButton(
              onLocationSelected: (value) {
                setState(() {
                  location.text = value.address;
                  latitude = value.latitude;
                  longitude = value.longitude;
                });
              },
            ),
          ),
          if (HarvestScope.of(context).role == UserRole.admin)
            SwitchListTile.adaptive(
              value: active,
              onChanged: (v) => setState(() => active = v),
              title: const Text('Visible to customers'),
            ),
          HarvestButton(label: 'Save market', onPressed: busy ? null : save),
        ],
      ),
    ),
  );
}

class PublishedContent extends StatelessWidget {
  const PublishedContent({super.key, this.contact = false});
  final bool contact;
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (!store.live && !(store.isDemo && Firebase.apps.isNotEmpty)) {
      return const SizedBox.shrink();
    }
    return StreamBuilder(
      stream: FirebaseFirestore.instance.doc('appConfig/public').snapshots(),
      builder: (context, snapshot) {
        final d = snapshot.data?.data();
        if (d == null) return const SizedBox.shrink();
        final text = contact
            ? [
                d['contactEmail'],
                d['contactName'],
                d['contactAddress'],
                d['contactPhone'],
              ].whereType<String>().where((v) => v.isNotEmpty).join('\n')
            : d['about'] as String? ?? '';
        if (text.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SelectableText(text),
        );
      },
    );
  }
}
