import 'customer_screens/notifications_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components.dart';
import 'customer.dart';
import 'models.dart';
import 'theme.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  int _activeTab = 0; // 0: Growth & Statistics, 1: AI Advisor
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<({bool user, String text})> _messages = [];
  bool _isTyping = false;

  static const List<String> _prompts = [
    'Which fruits are rich in Vitamin C?',
    'How should tomatoes be stored?',
    'Which vegetables are seasonal right now?',
    'What are the health benefits of spinach?',
    'Suggest vegetables for a healthy salad.',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _generateAnswer(String question) {
    final q = question.toLowerCase();
    // Match whole words so short tokens (e.g. "c") don't hit unrelated text.
    final words = q.split(RegExp(r'[^a-z0-9]+')).toSet();
    bool has(String stem) => words.any((w) => w.startsWith(stem));
    if (has('spinach') || has('iron') || has('benefit')) {
      return 'Spinach provides vital dietary fiber, iron, folate, and carotenoids (lutein & zeaxanthin) which support eye health and energy. Pairing raw spinach with Vitamin C (like fresh lemon juice) boosts plant iron absorption.\n\nReference: Food Nutrition Board & Horticultural Research.';
    }
    if (has('season') || has('avail')) {
      final store = HarvestScope.of(context);
      final inStock = store.products.where((p) => p.stock > 0).take(4);
      if (inStock.isEmpty) {
        return 'No local harvests are in stock right now. Follow your favourite farms to hear when they restock.';
      }
      return 'Current local seasonal harvests available directly from growers:\n\n${inStock.map((p) => '• ${p.name} (${money(p.price)}/${p.unit}) from ${store.farm(p.farmId).name}').join('\n')}\n\nVisit the Explore tab to browse fresh picks!';
    }
    if (has('salad') || has('recipe')) {
      return 'For a vibrant, wholesome salad:\n• Base: Crisp baby spinach & fresh leaves\n• Crunch: Shaved heirloom carrots & cucumber\n• Sweetness: Ripe vine tomatoes & fresh strawberries\n• Dressing: Cold-pressed olive oil, raw honey, lemon juice & sea salt.\n\nExplore our local farm catalog to discover these items harvested today!';
    }
    if (has('tomato') || has('stor') || has('keep') || has('fridge')) {
      return 'For whole fresh tomatoes, allow them to ripen at room temperature away from direct sunlight. Refrigeration can dull their aroma and make texture mealy. Only refrigerate once fully ripe or cut.\n\nTip: Let chilled tomatoes reach room temperature before slicing for maximum sweetness.\n\nReference: Agricultural & Food Extension Storage Guidelines.';
    }
    if (has('vitamin') || has('fruit') || has('citrus')) {
      return 'Strawberries, citrus fruits, guava, and bell peppers are exceptionally rich in Vitamin C. Consuming them raw or gently tossed preserves their delicate water-soluble vitamins.\n\nNote: General nutritional insight; not intended as medical advice.\n\nReference: USDA Dietary Guidelines for Fresh Produce.';
    }
    return 'I specialize in fresh produce wisdom, kitchen storage tips, and nutritional profiles for local farm harvests (e.g. tomatoes, spinach, seasonal fruits, and wholesome salads).\n\nFeel free to tap one of the suggested prompts below!';
  }

  void _send(String text) {
    final value = text.trim();
    if (value.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add((user: true, text: value));
      _input.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    // Gentle realistic processing delay
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add((user: false, text: _generateAnswer(value)));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAF8),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Statistic & Advisor',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: Harvest.ink,
        ),
      ),
      actions: [
        if (_activeTab == 1 && _messages.isNotEmpty)
          IconButton(
            tooltip: 'New conversation',
            onPressed: () => setState(() => _messages.clear()),
            icon: const Icon(Icons.refresh, size: 20),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircularNavButton(
              icon: Icons.notifications_none_outlined,
              hasBadge: true,
              onPressed: () => openPage(context, const NotificationsScreen()),
            ),
          ),
      ],
    ),
    body: Column(
      children: [
        // Segmented Header Toggle [Growth & Statistics | AI Advisor]
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Harvest.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _activeTab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 0
                            ? Harvest.forest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Growth & Statistics',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _activeTab == 0 ? Colors.white : Harvest.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _activeTab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 1
                            ? Harvest.forest
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'AI Harvest Advisor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _activeTab == 1 ? Colors.white : Harvest.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Body Content
        Expanded(
          child: _activeTab == 0 ? const _StatisticView() : _buildAdvisorView(),
        ),
      ],
    ),
  );

  Widget _buildAdvisorView() => Column(
    children: [
      Expanded(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            if (_messages.isEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Harvest.forest, Harvest.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Harvest.green.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Harvest.honey,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Harvest Assistant',
                style: Harvest.editorial(30),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Your guide to produce, nutrition & storage.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Harvest.muted, fontSize: 14),
              ),
              const SizedBox(height: 20),
              const InfoNote(
                'Verified produce knowledge base. Focuses on agricultural storage, seasonal produce and culinary wellness. Not medical diagnosis.',
                icon: Icons.eco_outlined,
              ),
              const SizedBox(height: 24),
              const Text(
                'Suggested inquiries',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Harvest.muted,
                ),
              ),
              const SizedBox(height: 10),
              for (final prompt in _prompts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _send(prompt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Harvest.border),
                          boxShadow: Harvest.cardShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Harvest.honey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                prompt,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Harvest.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ] else ...[
              for (final message in _messages)
                Align(
                  alignment: message.user
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: 14,
                      left: message.user ? 40 : 0,
                      right: message.user ? 0 : 40,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message.user ? Harvest.forest : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(message.user ? 20 : 4),
                        bottomRight: Radius.circular(message.user ? 4 : 20),
                      ),
                      border: Border.all(
                        color: message.user
                            ? Colors.transparent
                            : Harvest.border,
                      ),
                      boxShadow: Harvest.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!message.user) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.spa,
                                size: 13,
                                color: Harvest.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'HARVEST KNOWLEDGE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: Harvest.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        SelectableText(
                          message.text,
                          style: TextStyle(
                            color: message.user ? Colors.white : Harvest.ink,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isTyping)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Harvest.sage,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Harvest.forest,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Harvest Assistant is thinking…',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Harvest.forest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),

      // Premium composer bar
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Harvest.border)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    hintText: 'Ask about nutrition, produce storage…',
                    fillColor: Harvest.cream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Harvest.forest,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Harvest.forest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _send(_input.text),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _StatisticView extends StatefulWidget {
  const _StatisticView();

  @override
  State<_StatisticView> createState() => _StatisticViewState();
}

class _StatisticViewState extends State<_StatisticView> {
  String _period = 'Weekly';
  final Set<String> _joinedCommunities = {'Farming Community'};

  final List<({String name, String author, String location, String photo})>
  _communities = [
    (
      name: 'Farming Community',
      author: 'Gun Hawkins',
      location: 'New York, USA',
      photo: 'farm',
    ),
    (
      name: 'Agriculture Community',
      author: 'Gun Hawkins',
      location: 'New York, USA',
      photo: 'market',
    ),
    (
      name: 'Organic Growers Guild',
      author: 'Elena Vance',
      location: 'California, USA',
      photo: 'tomatoes',
    ),
    (
      name: 'Permaculture Collective',
      author: 'Marcus Thorne',
      location: 'Oregon, USA',
      photo: 'strawberries',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
    children: [
      // 1. Growth Spline Area Chart matching Reference 2 (Screen 4)
      GrowthAreaChart(
        title: 'Growth',
        period: _period,
        onPeriodChange: () {
          setState(() {
            _period = _period == 'Weekly' ? 'Monthly' : 'Weekly';
          });
          HapticFeedback.selectionClick();
        },
      ),
      const SizedBox(height: 24),

      // 2. Weather Advisory & Notes banner shortcut
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openPage(context, const TodaysWeatherScreen()),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Harvest.forest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180E4D34),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 24),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today’s Weather: 33°C Cloudy',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap to view crop observation notes & field logs',
                      style: TextStyle(color: Color(0xFFD4E3D7), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),

      // 3. Community List matching Reference 2 (Screen 4)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Community',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Harvest.ink,
            ),
          ),
          TextButton(
            onPressed: () =>
                notice(context, 'Showing all verified local grower circles'),
            child: const Text(
              'View all',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),

      for (final comm in _communities)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Harvest.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Photo(comm.photo, width: 48, height: 48, radius: 14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comm.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Harvest.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${comm.author} · ${comm.location}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Harvest.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      if (_joinedCommunities.contains(comm.name)) {
                        _joinedCommunities.remove(comm.name);
                      } else {
                        _joinedCommunities.add(comm.name);
                      }
                    });
                    HapticFeedback.lightImpact();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _joinedCommunities.contains(comm.name)
                        ? Colors.white
                        : Harvest.forest,
                    backgroundColor: _joinedCommunities.contains(comm.name)
                        ? Harvest.forest
                        : Colors.white,
                    side: BorderSide(
                      color: _joinedCommunities.contains(comm.name)
                          ? Harvest.forest
                          : Harvest.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Text(
                    _joinedCommunities.contains(comm.name)
                        ? 'Joined'
                        : 'Gabung',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
