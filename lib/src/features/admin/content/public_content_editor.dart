import 'package:flutter/material.dart';

import '../../common/data/models.dart';
import '../../common/data/public_content.dart';
import '../../common/shared/components.dart';
import '../../common/shared/forms/phone_field.dart';
import '../../common/shared/forms/phone_validation.dart';
import '../../authentication/authentication.dart';
import '../../common/about_us/about_page.dart';

class PublicContentEditor extends StatefulWidget {
  const PublicContentEditor({super.key, this.repository});
  final PublicContentRepository? repository;

  @override
  State<PublicContentEditor> createState() => _PublicContentEditorState();
}

class _PublicContentEditorState extends State<PublicContentEditor> {
  final form = GlobalKey<FormState>();
  final fields = {
    for (final key in PublicContent.defaults.keys) key: TextEditingController(),
  };
  PublicContentRepository? _repository;
  bool _started = false, loading = true, busy = false;
  String? error;

  bool get _allowed {
    final store = HarvestScope.of(context);
    return store.role == UserRole.admin && (!store.live || store.authenticated);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !_allowed) return;
    _started = true;
    _repository =
        widget.repository ??
        (HarvestScope.of(context).live ? PublicContentRepository() : null);
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final content = await _repository?.load() ?? PublicContent.fromData(null);
      if (!mounted) return;
      for (final entry in fields.entries) {
        entry.value.text = content[entry.key];
      }
    } catch (_) {
      if (mounted) error = 'Content could not load. Retry before editing.';
    }
    if (mounted) setState(() => loading = false);
  }

  PublicContent get _draft => PublicContent.fromData({
    for (final entry in fields.entries) entry.key: entry.value.text.trim(),
    'aboutVersion': 1,
  });

  String? _imageError(String text) {
    if (text.isEmpty || text == 'market') return null;
    final uri = Uri.tryParse(text);
    return text.length <= 2000 &&
            uri?.scheme == 'https' &&
            (uri?.host.isNotEmpty ?? false)
        ? null
        : 'Use an HTTPS image URL, market, or leave blank.';
  }

  bool _validateDraft() {
    // Fields above the viewport may be unmounted by ListView. Validate their
    // controller values too, so publishing cannot bypass required fields.
    const requiredFields = {
      'aboutPageTitle': 'Page title',
      'aboutHeadline': 'Main headline',
      'about': 'Story text',
    };
    for (final entry in requiredFields.entries) {
      if (fields[entry.key]!.text.trim().isEmpty) {
        notice(context, '${entry.value} is required.', isError: true);
        return false;
      }
    }
    if (!form.currentState!.validate()) return false;
    form.currentState!.save();
    for (final entry in fields.entries) {
      final limit = entry.key == 'aboutImage'
          ? 2000
          : [
              'about',
              'aboutCommunityBody',
              'aboutSimpleBody',
              'aboutHeadline',
            ].contains(entry.key)
          ? 5000
          : 300;
      if (entry.value.text.trim().length > limit) {
        notice(
          context,
          'Please shorten the text before publishing.',
          isError: true,
        );
        return false;
      }
    }
    final email = fields['contactEmail']!.text.trim();
    final validationError =
        _imageError(fields['aboutImage']!.text.trim()) ??
        (email.isEmpty ? null : emailValidator(email)) ??
        phoneNumberError(
          fields['contactPhone']!.text,
          required: false,
          mobileOnly: false,
        );
    if (validationError != null) {
      notice(context, validationError, isError: true);
      return false;
    }
    return true;
  }

  Future<void> save() async {
    if (!_allowed || busy || !_validateDraft()) return;
    if (_repository == null) {
      notice(context, 'Preview mode: content has not been published.');
      return;
    }
    setState(() => busy = true);
    try {
      await _repository!.publish(_draft);
      if (mounted) notice(context, 'About page and support details published');
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not publish content. Your draft is kept; please retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget field(
    String key,
    String label, {
    int lines = 1,
    bool required = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: HarvestField(
      key: ValueKey(key),
      controller: fields[key]!,
      label: label,
      lines: lines,
      validator: (value) {
        final text = (value ?? '').trim();
        if (required && text.isEmpty) return 'Enter $label.';
        if (text.length > (lines > 1 ? 5000 : 300)) {
          return 'Please shorten this text.';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_allowed) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('About & public content')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  TextButton(onPressed: load, child: const Text('Retry')),
                ],
              ),
            )
          : Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const InfoNote(
                    'Edit the content shown on the About page. Preview your draft, then publish to update it for everyone. Leave optional sections blank to hide them.',
                  ),
                  const SectionHeader('Page introduction'),
                  field('aboutPageTitle', 'Page title', required: true),
                  field('aboutEyebrow', 'Small heading'),
                  field(
                    'aboutHeadline',
                    'Main headline',
                    lines: 2,
                    required: true,
                  ),
                  HarvestField(
                    key: const ValueKey('aboutImage'),
                    controller: fields['aboutImage']!,
                    label: 'Image URL (or market for the original image)',
                    validator: (value) => _imageError((value ?? '').trim()),
                  ),
                  const SizedBox(height: 16),
                  field('aboutImageLabel', 'Image description'),
                  const SectionHeader('Our story'),
                  field('aboutStoryTitle', 'Story heading'),
                  field('about', 'Story text', lines: 6, required: true),
                  const SectionHeader('Community'),
                  field('aboutCommunityTitle', 'Community heading'),
                  field('aboutCommunityBody', 'Community text', lines: 4),
                  const SectionHeader('Our approach'),
                  field('aboutSimpleTitle', 'Approach heading'),
                  field('aboutSimpleBody', 'Approach text', lines: 4),
                  const SectionHeader('Page footer'),
                  field('aboutFooterBrand', 'Footer name'),
                  field('aboutFooterTagline', 'Footer tagline'),
                  const SectionHeader('Support contact'),
                  HarvestField(
                    controller: fields['contactEmail']!,
                    label: 'Public support email',
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? null : emailValidator(v),
                  ),
                  const SizedBox(height: 16),
                  PhoneField(
                    controller: fields['contactPhone']!,
                    label: 'Public support phone',
                    required: false,
                    mobileOnly: false,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () {
                            if (!_validateDraft()) return;
                            openPage(context, AboutScreen(preview: _draft));
                          },
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('Preview About page'),
                  ),
                  const SizedBox(height: 12),
                  HarvestButton(
                    label: busy ? 'Publishing…' : 'Publish content',
                    onPressed: busy ? null : save,
                  ),
                ],
              ),
            ),
    );
  }
}
