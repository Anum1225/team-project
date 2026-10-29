import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/public_content.dart';
import '../shared/components.dart';
import '../shared/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key, this.repository, this.preview});
  final PublicContentRepository? repository;
  final PublicContent? preview;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Stream<PublicContent>? _content;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.preview == null &&
        (widget.repository != null ||
            HarvestScope.of(context).live ||
            (HarvestScope.of(context).isDemo && Firebase.apps.isNotEmpty))) {
      _content = (widget.repository ?? PublicContentRepository()).watch();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<PublicContent>(
    stream: _content,
    initialData: widget.preview ?? PublicContent.fromData(null),
    builder: (context, snapshot) {
      final content = snapshot.data ?? PublicContent.fromData(null);
      return HarvestPage(
        title: content['aboutPageTitle'],
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.preview != null)
              const InfoNote(
                'Preview — these changes have not been published.',
              ),
            if (snapshot.hasError)
              const InfoNote(
                'Unable to refresh this page. Showing the last available content.',
              ),
            const SeedMark(size: 46),
            const SizedBox(height: 24),
            if (content['aboutEyebrow'].isNotEmpty) ...[
              Eyebrow(content['aboutEyebrow']),
              const SizedBox(height: 14),
            ],
            Text(content['aboutHeadline'], style: Harvest.editorial(40)),
            if (content['aboutImage'].isNotEmpty) ...[
              const SizedBox(height: 24),
              Photo(
                content['aboutImage'],
                height: 240,
                width: double.infinity,
                radius: 28,
                label: content['aboutImageLabel'],
              ),
            ],
            const SizedBox(height: 28),
            if (content['aboutStoryTitle'].isNotEmpty) ...[
              Text(content['aboutStoryTitle'], style: Harvest.editorial(28)),
              const SizedBox(height: 14),
            ],
            Text(content['about']),
            for (final section in ['Community', 'Simple']) ...[
              if (content['about${section}Title'].isNotEmpty)
                SectionHeader(content['about${section}Title']),
              if (content['about${section}Body'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(content['about${section}Body']),
                ),
            ],
            if (content['aboutFooterBrand'].isNotEmpty ||
                content['aboutFooterTagline'].isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 20),
              if (content['aboutFooterBrand'].isNotEmpty)
                Eyebrow(content['aboutFooterBrand']),
              const SizedBox(height: 8),
              Text(
                content['aboutFooterTagline'],
                style: TextStyle(color: Harvest.colors(context).muted),
              ),
            ],
          ],
        ),
      );
    },
  );
}
