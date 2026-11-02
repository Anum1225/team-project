import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/components.dart';
import '../data/models.dart';
import '../data/trusted_backend.dart';
import 'live_inbox.dart';
import '../../authentication/demo/guest_sign_in.dart';

class HarvestNotifications {
  // Enable only after the trusted push sender has been deployed and verified.
  static bool get pushBackendEnabled =>
      TrustedBackend.enabled ||
      const bool.fromEnvironment('PUSH_BACKEND_ENABLED');
  static StreamSubscription<String>? _refresh;
  static String? _token;
  static Future<void> restore() async {
    if (!pushBackendEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(
          'harvesthub_push_enabled_${Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid}',
        ) ==
        true) {
      await register();
    }
  }

  static Future<void> register() async {
    if (!pushBackendEnabled) {
      throw StateError('Phone notifications are not available yet.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    Future<void> save(String token) async {
      if (FirebaseAuth.instance.currentUser?.uid != uid) return;
      _token = token;
      await FirebaseFirestore.instance.doc('users/$uid/devices/$token').set({
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      throw StateError('The phone could not register for notifications.');
    }
    await save(token);
    await _refresh?.cancel();
    _refresh = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(save(token).catchError((Object _) {}));
    });
  }

  static Future<void> unregister() async {
    final refresh = _refresh;
    _refresh = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final token = _token;
    _token = null;
    // Start all cleanup for this session now; an offline device-document delete
    // must not postpone deleting the messaging token until after the next login.
    await Future.wait([
      if (refresh != null) refresh.cancel(),
      if (uid != null && token != null)
        FirebaseFirestore.instance.doc('users/$uid/devices/$token').delete(),
      if (pushBackendEnabled) FirebaseMessaging.instance.deleteToken(),
    ]);
  }
}

/// Uses the same authorized order queries as the marketplace, on Firebase Spark.
Stream<QuerySnapshot<Map<String, dynamic>>> orderUpdates(
  String uid,
  UserRole role,
) {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
    'orders',
  );
  if (role == UserRole.customer) {
    query = query.where('customerId', isEqualTo: uid);
  }
  if (role == UserRole.farmer) query = query.where('farmerId', isEqualTo: uid);
  return query.orderBy('createdAt', descending: true).limit(100).snapshots();
}

DateTime orderUpdateTime(Map<String, dynamic> data) =>
    (data['updatedAt'] ?? data['createdAt']) is Timestamp
    ? ((data['updatedAt'] ?? data['createdAt']) as Timestamp).toDate()
    : DateTime.fromMillisecondsSinceEpoch(0);

/// Live inbox badge reflects unread records in the signed-in user's database.
class InboxIndicator extends StatefulWidget {
  const InboxIndicator({super.key, required this.onOpen});
  final Future<void> Function() onOpen;
  @override
  State<InboxIndicator> createState() => _InboxIndicatorState();
}

class _InboxIndicatorState extends State<InboxIndicator> {
  String? uid;
  int seenOrdersAt = 0;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = HarvestScope.of(context);
    if (!store.live || Firebase.apps.isEmpty || uid == store.account.id) return;
    uid = store.account.id;
    if (store.role == UserRole.admin) {
      final accountId = uid;
      SharedPreferences.getInstance().then((prefs) {
        if (mounted && uid == accountId) {
          setState(() {
            seenOrdersAt =
                prefs.getInt('harvesthub_admin_orders_seen_$accountId') ?? 0;
          });
        }
      });
    }
  }

  Future<void> open() async {
    final store = HarvestScope.of(context);
    if (store.role == UserRole.admin && uid != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() => seenOrdersAt = now);
      await (await SharedPreferences.getInstance()).setInt(
        'harvesthub_admin_orders_seen_$uid',
        now,
      );
    }
    await widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    Widget button(bool unread) => IconButton(
      tooltip: 'Notifications',
      onPressed: open,
      icon: Badge(
        isLabelVisible: unread,
        backgroundColor: Colors.red,
        smallSize: 8,
        child: const Icon(Icons.notifications_none_rounded, size: 22),
      ),
    );
    if (uid == null) return button(false);
    final store = HarvestScope.of(context);
    return StreamBuilder(
      stream: notificationInbox(uid!),
      builder: (_, snapshot) {
        final unreadInbox =
            snapshot.data?.docs.any((doc) => doc.data()['readAt'] == null) ??
            false;
        if (store.role != UserRole.admin) return button(unreadInbox);
        return StreamBuilder(
          stream: pendingAccountUpdates(),
          builder: (_, accounts) => StreamBuilder(
            stream: pendingMarketUpdates(),
            builder: (_, markets) => StreamBuilder(
              stream: orderUpdates(uid!, UserRole.admin),
              builder: (_, orders) => button(
                unreadInbox ||
                    (accounts.data?.docs.isNotEmpty ?? false) ||
                    (markets.data?.docs.isNotEmpty ?? false) ||
                    (orders.data?.docs.any(
                          (doc) =>
                              orderUpdateTime(doc.data())
                                  .millisecondsSinceEpoch >
                              seenOrdersAt,
                        ) ??
                        false),
              ),
            ),
          ),
        );
      },
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.inbox});
  final Widget? inbox;
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
        setState(
          () => enabled =
              HarvestNotifications.pushBackendEnabled &&
              (p.getBool(
                    'harvesthub_push_enabled_${Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid}',
                  ) ??
                  false),
        );
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
        'harvesthub_push_enabled_${Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid}',
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
      appBar: AppBar(
        titleSpacing: store.role == UserRole.admin ? 24 : null,
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      store.role == UserRole.admin ? 28 : 20,
                      16,
                      24,
                      16,
                    ),
                    child: const Text(
                      'Your market, in the loop.',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.fromLTRB(
                      store.role == UserRole.admin ? 24 : 20,
                      8,
                      20,
                      8,
                    ),
                    value: enabled,
                    onChanged:
                        busy ||
                            !store.live ||
                            !HarvestNotifications.pushBackendEnabled
                        ? null
                        : toggle,
                    title: const Text('Phone notifications'),
                    subtitle: Text(
                      HarvestNotifications.pushBackendEnabled
                          ? 'Receive order updates on your phone.'
                          : 'Phone alerts are unavailable. Live order updates appear below.',
                    ),
                  ),
                ),
              ],
              body: widget.inbox ?? _buildInbox(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInbox(BuildContext context) {
    final store = HarvestScope.of(context);
    return store.isDemo
        ? const GuestAccountPrompt(title: 'Your notifications')
        : !store.live
        ? const NotificationMessage(
            'You’re all caught up. New updates will appear here.',
          )
        : const LiveNotificationInbox();
  }
}
