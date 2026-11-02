import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components.dart';
import 'theme.dart';

class HarvestNotifications {
  static StreamSubscription<String>? _refresh;
  static String? _token;
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('harvesthub_push_enabled') == true) await register();
  }

  static Future<void> register() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    Future<void> save(String token) async {
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      _token = token;
      await FirebaseFirestore.instance.doc('users/$uid/devices/$token').set({
        'platform': 'android',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await save(token);
    await _refresh?.cancel();
    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(save(token).catchError((Object _) {}));
    });
  }

  static Future<void> unregister() async {
    await _refresh?.cancel();
    _refresh = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      if (uid != null && _token != null) {
        await FirebaseFirestore.instance
            .doc('users/$uid/devices/$_token')
            .delete();
      }
    } finally {
      _token = null;
      await FirebaseMessaging.instance.deleteToken();
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool enabled = false, busy = false;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => enabled = p.getBool('harvesthub_push_enabled') ?? false);
      }
    });
  }

  Future<void> toggle(bool value) async {
    setState(() => busy = true);
    try {
      if (value) {
        final settings = await FirebaseMessaging.instance.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          throw StateError('Allow notifications in your phone settings first.');
        }
        await HarvestNotifications.register();
      } else {
        await HarvestNotifications.unregister();
      }
      await (await SharedPreferences.getInstance()).setBool(
        'harvesthub_push_enabled',
        value,
      );
      if (mounted) setState(() => enabled = value);
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not change notification settings. Check phone permissions and retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Column(
        children: [
          SwitchListTile.adaptive(
            value: enabled,
            onChanged: busy || !store.live ? null : toggle,
            title: const Text('Phone notifications'),
            subtitle: const Text(
              'Order updates, pickup changes and restock alerts.',
            ),
          ),
          Expanded(
            child: !store.live
                ? const Center(child: Text('No notifications.'))
                : StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users/${store.account.id}/notifications')
                        .orderBy('createdAt', descending: true)
                        .limit(100)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Notifications could not load. Pull back and try again.',
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('You’re all caught up.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final d = docs[i].data();
                          return ListTile(
                            leading: Icon(
                              Icons.notifications_outlined,
                              color: Harvest.colors(context).green,
                            ),
                            title: Text(
                              d['title'] as String? ?? 'HarvestHub update',
                            ),
                            subtitle: Text(d['body'] as String? ?? ''),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
