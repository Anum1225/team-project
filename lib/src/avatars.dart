import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'components.dart';
import 'models.dart';
import 'theme.dart';

const _portraits =
    <({String name, Color background, Color shirt, Color hat, Color skin})>[
      (
        name: 'Amina',
        background: Color(0xFFD9F0DE),
        shirt: Color(0xFF28744A),
        hat: Color(0xFFF0B34A),
        skin: Color(0xFFB96F4F),
      ),
      (
        name: 'Hamza',
        background: Color(0xFFE5E8CE),
        shirt: Color(0xFF315D48),
        hat: Color(0xFFDA9340),
        skin: Color(0xFF8F573F),
      ),
      (
        name: 'Sara',
        background: Color(0xFFF1E7C7),
        shirt: Color(0xFF6F8D53),
        hat: Color(0xFFDB6D42),
        skin: Color(0xFFD3936C),
      ),
      (
        name: 'Bilal',
        background: Color(0xFFD9EAE7),
        shirt: Color(0xFF3F7580),
        hat: Color(0xFFE9B953),
        skin: Color(0xFFAA684A),
      ),
      (
        name: 'Noor',
        background: Color(0xFFF2DEDA),
        shirt: Color(0xFF785C75),
        hat: Color(0xFF5E9559),
        skin: Color(0xFFDBA27A),
      ),
      (
        name: 'Daniyal',
        background: Color(0xFFE4E1F2),
        shirt: Color(0xFF416A57),
        hat: Color(0xFFBD7C38),
        skin: Color(0xFF704833),
      ),
      (
        name: 'Zara',
        background: Color(0xFFDDF0EC),
        shirt: Color(0xFF357F72),
        hat: Color(0xFFE5A54B),
        skin: Color(0xFFCB8966),
      ),
      (
        name: 'Omar',
        background: Color(0xFFF2E7D7),
        shirt: Color(0xFF536A3C),
        hat: Color(0xFFC95D3C),
        skin: Color(0xFF966046),
      ),
      (
        name: 'Mariam',
        background: Color(0xFFE4EDCF),
        shirt: Color(0xFF71613E),
        hat: Color(0xFF43885C),
        skin: Color(0xFFB87556),
      ),
      (
        name: 'Yusuf',
        background: Color(0xFFD9E4F0),
        shirt: Color(0xFF38665E),
        hat: Color(0xFFD7A249),
        skin: Color(0xFF80523B),
      ),
      (
        name: 'Hira',
        background: Color(0xFFF0E1EB),
        shirt: Color(0xFF487F5B),
        hat: Color(0xFFD1784C),
        skin: Color(0xFFDAA17D),
      ),
      (
        name: 'Ibrahim',
        background: Color(0xFFE8E9D7),
        shirt: Color(0xFF426079),
        hat: Color(0xFFE5B64E),
        skin: Color(0xFFA76B4C),
      ),
    ];

/// A compact, original illustrated portrait with a persistent profile key.
class AvatarPortrait extends StatelessWidget {
  const AvatarPortrait({super.key, required this.value, required this.size});
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final parsed =
        int.tryParse(value.startsWith('preset:') ? value.substring(7) : '') ??
        0;
    if (value.startsWith('data:image/') && value.contains(',')) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(value.substring(value.indexOf(',') + 1)),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _art(parsed),
          ),
        );
      } catch (_) {
        return _art(parsed);
      }
    }
    return _art(parsed);
  }

  Widget _art(int index) => ClipOval(
    child: CustomPaint(
      size: Size.square(size),
      painter: _PortraitPainter(index: index % _portraits.length),
    ),
  );
}

class _PortraitPainter extends CustomPainter {
  const _PortraitPainter({required this.index});
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final s = _portraits[index];
    final scale = d / 100;
    canvas.save();
    canvas.scale(scale);
    final bg = Paint()..color = s.background;
    canvas.drawCircle(const Offset(50, 50), 50, bg);

    // Soft greenhouse light and two small leaves frame each portrait.
    canvas.drawCircle(
      const Offset(50, 24),
      19,
      Paint()..color = Colors.white.withValues(alpha: .31),
    );
    final leaf = Paint()
      ..color = const Color(0xFF539662).withValues(alpha: .75);
    canvas.save();
    canvas.translate(15, 56);
    canvas.rotate(-.7);
    canvas.drawOval(const Rect.fromLTWH(-4, -12, 13, 23), leaf);
    canvas.restore();
    canvas.save();
    canvas.translate(85, 52);
    canvas.rotate(.8);
    canvas.drawOval(const Rect.fromLTWH(-4, -12, 13, 23), leaf);
    canvas.restore();

    final shirt = Paint()..color = s.shirt;
    final body = Path()
      ..moveTo(17, 103)
      ..quadraticBezierTo(19, 68, 39, 66)
      ..lineTo(61, 66)
      ..quadraticBezierTo(81, 68, 83, 103)
      ..close();
    canvas.drawPath(body, shirt);
    canvas.drawCircle(const Offset(50, 48), 22, Paint()..color = s.skin);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(27, 49), width: 7, height: 12),
      Paint()..color = s.skin,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(73, 49), width: 7, height: 12),
      Paint()..color = s.skin,
    );

    final hair = Paint()..color = const Color(0xFF3D3028);
    final hairPath = Path()
      ..moveTo(28, 45)
      ..quadraticBezierTo(26, 19, 50, 23)
      ..quadraticBezierTo(74, 22, 72, 46)
      ..quadraticBezierTo(64, 34, 56, 35)
      ..quadraticBezierTo(43, 39, 28, 45)
      ..close();
    canvas.drawPath(hairPath, hair);
    canvas.drawOval(
      const Rect.fromLTWH(29, 14, 42, 14),
      Paint()..color = s.hat,
    );
    canvas.drawArc(
      const Rect.fromLTWH(21, 21, 58, 14),
      0,
      3.14,
      false,
      Paint()
        ..color = s.hat.withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    final feature = Paint()
      ..color = const Color(0xFF382D29)
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(39, 49), const Offset(43, 49), feature);
    canvas.drawLine(const Offset(57, 49), const Offset(61, 49), feature);
    canvas.drawArc(
      const Rect.fromLTWH(42, 53, 16, 10),
      .2,
      2.75,
      false,
      feature,
    );
    canvas.drawLine(
      const Offset(50, 50),
      const Offset(48.5, 55),
      Paint()
        ..color = s.skin.withValues(alpha: .68)
        ..strokeWidth = 1.4,
    );
    canvas.drawLine(
      const Offset(50, 69),
      const Offset(50, 83),
      Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter oldDelegate) =>
      index != oldDelegate.index;
}

class ProfileAvatarPicker extends StatefulWidget {
  const ProfileAvatarPicker({super.key, required this.account});
  final Account account;
  @override
  State<ProfileAvatarPicker> createState() => _ProfileAvatarPickerState();
}

class _ProfileAvatarPickerState extends State<ProfileAvatarPicker> {
  bool _saving = false;

  Future<void> _save(String value) async {
    setState(() => _saving = true);
    final a = widget.account;
    final result = await HarvestScope.of(context).saveAccount(
      Account(
        id: a.id,
        name: a.name,
        email: a.email,
        role: a.role,
        phone: a.phone,
        address: a.address,
        avatar: value,
        active: a.active,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result != null) {
      notice(context, result, isError: true);
      return;
    }
    Navigator.pop(context);
    notice(context, 'Profile picture updated');
  }

  Future<void> _upload() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 256,
      maxHeight: 256,
      imageQuality: 72,
    );
    if (file == null || !mounted) return;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 100000) {
        if (mounted) notice(context, 'Choose a smaller photo.', isError: true);
        return;
      }
      await _save('data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not read that photo. Try another one.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Harvest.colors(context);
    final selected = widget.account.avatar;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('Choose your portrait')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
            child: Row(
              children: [
                AvatarPortrait(value: selected, size: 66),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Pick a HarvestHub portrait or use a photo from your gallery.',
                    style: TextStyle(color: palette.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _upload,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Upload a photo'),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .9,
              ),
              itemCount: _portraits.length,
              itemBuilder: (context, i) {
                final active = selected == 'preset:$i';
                return Semantics(
                  button: true,
                  label: 'Choose ${_portraits[i].name} portrait',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _saving ? null : () => _save('preset:$i'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 190),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? palette.green : palette.border,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AvatarPortrait(value: 'preset:$i', size: 72),
                          const SizedBox(height: 7),
                          Text(
                            _portraits[i].name,
                            style: TextStyle(
                              color: palette.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_saving) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
