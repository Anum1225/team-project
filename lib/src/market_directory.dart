import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth.dart';
import 'components.dart';
import 'location_picker.dart';
import 'models.dart';

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
          if (admin)
            IconButton(
              tooltip: 'Add market',
              icon: const Icon(Icons.add),
              onPressed: () => openPage(context, const MarketEditor()),
            ),
        ],
      ),
      body: !store.live
          ? const Center(child: Text('No markets published.'))
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('farmersMarkets')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load markets. Please reopen this page.',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!.docs
                    .where((d) => admin || d.data()['active'] == true)
                    .toList();
                if (rows.isEmpty) {
                  return const Center(child: Text('No markets published yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final doc = rows[i], d = doc.data();
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
                            Text(d['location'] as String? ?? ''),
                            const SizedBox(height: 8),
                            Text('Hours: ${d['hours'] ?? 'Not published'}'),
                            if (d['lat'] != null && d['lng'] != null)
                              Text('Map coordinates: ${d['lat']}, ${d['lng']}'),
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
                                  MarketEditor(id: doc.id, data: d),
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
      final ref = FirebaseFirestore.instance
          .collection('farmersMarkets')
          .doc(widget.id);
      await ref.set({
        'name': name.text.trim(),
        'location': location.text.trim(),
        'hours': hours.text.trim(),
        'lat': latitude,
        'lng': longitude,
        'active': active,
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
              onSelected: (value) {
                final parts = value.split(',');
                setState(() {
                  latitude = double.tryParse(parts.first.trim());
                  longitude = double.tryParse(parts.last.trim());
                });
              },
            ),
          ),
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

class PublicContentEditor extends StatefulWidget {
  const PublicContentEditor({super.key});
  @override
  State<PublicContentEditor> createState() => _PublicContentEditorState();
}

class _PublicContentEditorState extends State<PublicContentEditor> {
  final about = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController();
  final form = GlobalKey<FormState>();
  bool loading = true, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d =
          (await FirebaseFirestore.instance.doc('appConfig/public').get())
              .data() ??
          {};
      about.text = d['about'] as String? ?? '';
      email.text = d['contactEmail'] as String? ?? '';
      phone.text = d['contactPhone'] as String? ?? '';
    } catch (_) {
      error = 'Content could not load. Reopen this page to retry.';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  void dispose() {
    about.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await FirebaseFirestore.instance.doc('appConfig/public').set({
        'about': about.text.trim(),
        'contactEmail': email.text.trim(),
        'contactPhone': phone.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) notice(context, 'Public content published');
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not publish content. Please retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Public content')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : Form(
            key: form,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                HarvestField(
                  controller: about,
                  label: 'About HarvestHub',
                  lines: 7,
                ),
                const SizedBox(height: 16),
                HarvestField(
                  controller: email,
                  label: 'Public support email',
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? null : emailValidator(v),
                ),
                const SizedBox(height: 16),
                HarvestField(
                  controller: phone,
                  label: 'Public support phone',
                  validator: (v) => null,
                ),
                const SizedBox(height: 24),
                HarvestButton(
                  label: 'Publish content',
                  onPressed: busy ? null : save,
                ),
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
    if (!HarvestScope.of(context).live) return const SizedBox.shrink();
    return StreamBuilder(
      stream: FirebaseFirestore.instance.doc('appConfig/public').snapshots(),
      builder: (context, snapshot) {
        final d = snapshot.data?.data();
        if (d == null) return const SizedBox.shrink();
        final text = contact
            ? [
                d['contactEmail'],
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
