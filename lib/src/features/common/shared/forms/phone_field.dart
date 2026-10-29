import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'phone_countries.dart';
import 'phone_validation.dart';

/// Country-aware entry. Form.save writes a validated E.164 value to controller.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.label = 'Mobile phone',
    this.required = true,
    this.mobileOnly = true,
  });
  final TextEditingController controller;
  final String label;
  final bool required;
  final bool mobileOnly;
  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  IsoCode _country = IsoCode.PK;
  final _field = GlobalKey<FormFieldState<String>>();
  @override
  void initState() {
    super.initState();
    _country = parsedPhoneNumber(widget.controller.text)?.isoCode ?? IsoCode.PK;
    widget.controller.addListener(_detectInternationalCountry);
  }

  @override
  void didUpdateWidget(covariant PhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_detectInternationalCountry);
      widget.controller.addListener(_detectInternationalCountry);
      _detectInternationalCountry();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_detectInternationalCountry);
    super.dispose();
  }

  void _detectInternationalCountry() {
    final text = widget.controller.text.trim();
    if (!text.startsWith('+') && !text.startsWith('00')) return;
    final parsed = parsedPhoneNumber(text, country: _country);
    if (parsed != null && parsed.isValid() && parsed.isoCode != _country) {
      setState(() => _country = parsed.isoCode);
    }
  }

  Future<void> _selectCountry() async {
    final selected = await showDialog<IsoCode>(
      context: context,
      builder: (_) => _CountryPicker(selected: _country),
    );
    if (selected == null || !mounted || selected == _country) return;
    final parsed = parsedPhoneNumber(widget.controller.text, country: _country);
    if (parsed != null &&
        (widget.controller.text.trim().startsWith('+') ||
            widget.controller.text.trim().startsWith('00'))) {
      widget.controller.text = parsed.nsn;
    }
    setState(() => _country = selected);
    if (_field.currentState?.hasError ?? false) _field.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _selectCountry,
          icon: const Icon(Icons.public, size: 18),
          label: Text(
            '${phoneCountryNames[_country]} (+${phoneDialCode(_country)})  ▾',
          ),
        ),
      ),
      TextFormField(
        key: _field,
        controller: widget.controller,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.telephoneNumber],
        inputFormatters: [LengthLimitingTextInputFormatter(40)],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: _country == IsoCode.PK
              ? '03XX XXXXXXX'
              : 'National phone number',
          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
          errorMaxLines: 3,
        ),
        validator: (value) => phoneNumberError(
          value,
          country: _country,
          required: widget.required,
          mobileOnly: widget.mobileOnly,
        ),
        onSaved: (value) => widget.controller.text = normalizePhoneNumber(
          value ?? '',
          country: _country,
          required: widget.required,
          mobileOnly: widget.mobileOnly,
        ),
      ),
    ],
  );
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({required this.selected});
  final IsoCode selected;
  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _search = '';
  late final _countries = [...IsoCode.values]
    ..sort((a, b) {
      if (a == b) return 0;
      if (a == IsoCode.PK) return -1;
      if (b == IsoCode.PK) return 1;
      return phoneCountryNames[a]!.compareTo(phoneCountryNames[b]!);
    });
  @override
  Widget build(BuildContext context) {
    final matches = _countries
        .where(
          (country) =>
              '${phoneCountryNames[country]} ${country.name} +${phoneDialCode(country)}'
                  .toLowerCase()
                  .contains(_search.toLowerCase()),
        )
        .toList();
    return AlertDialog(
      title: const Text('Phone country code'),
      content: SizedBox(
        width: 380,
        height: 400,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search country or code',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: matches.isEmpty
                  ? const Center(child: Text('No countries found'))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final country = matches[index];
                        return ListTile(
                          title: Text(phoneCountryNames[country]!),
                          subtitle: Text('+${phoneDialCode(country)}'),
                          trailing: country == widget.selected
                              ? const Icon(Icons.check)
                              : null,
                          onTap: () => Navigator.pop(context, country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
