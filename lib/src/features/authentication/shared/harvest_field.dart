part of '../authentication.dart';

class HarvestField extends StatelessWidget {
  const HarvestField({
    super.key,
    required this.controller,
    this.label = '',
    this.hint,
    this.prefixIcon,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.lines = 1,
    this.autofillHints,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboard;
  final bool obscure;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final int lines;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: lines > 1 && keyboard == TextInputType.text
        ? TextInputType.multiline
        : keyboard,
    obscureText: obscure,
    maxLines: lines,
    validator: validator ?? requiredValidator,
    autofillHints: autofillHints,
    onChanged: onChanged,
    style: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 15,
      color: Harvest.colors(context).ink,
    ),
    decoration: InputDecoration(
      labelText: label.isNotEmpty ? label : null,
      hintText: hint,
      alignLabelWithHint: lines > 1,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: Harvest.colors(context).muted),
      suffixIcon: suffix,
    ),
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
  );
}

/// Sleek Password Reset & Account Recovery Screen
