import 'package:flutter/material.dart';

import '../data/pickup_slots.dart';
import '../data/sample_catalog.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<({bool user, String text})> messages = [
    (
      user: false,
      text: 'Hello, fresh-food friend! 🌱 I can help with produce storage, seasonal ideas, simple salads, and the sample farms in HarvestHub. What is on your mind?',
    ),
  ];
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  String answer(String question) {
    final q = question.toLowerCase();
    if (q.contains('stock') || q.contains('available')) {
      return 'In our demo catalog: ${products.where((p) => widget.store.stock(p) > 0).map((p) => '${p.name} (${widget.store.stock(p)} available)').join(', ')}. Check the product page before adding to your basket.';
    }
    if (q.contains('pickup') || q.contains('timing')) {
      return 'Choose a pickup window for each farm during checkout. The sample slots are ${pickupSlots().join('; ')}. Open Orders → View details → Manage booking to change or cancel a pickup.';
    }
    if (q.contains('farmer') || q.contains('market')) {
      return 'Meet ${farmers.map((f) => '${f.name} at ${f.market} in ${f.location}').join('; ')}. Open a farm profile to browse its products and follow it.';
    }
    if (q.contains('vitamin') || q.contains('fruit')) {
      return 'Oranges, guavas, strawberries, and kiwifruit are familiar fruit choices that contain vitamin C. Choose a variety of seasonal produce as part of your everyday meals.';
    }
    if (q.contains('tomato') || q.contains('storage') || q.contains('store')) {
      return 'Keep unripe whole tomatoes at room temperature, away from direct sun. Refrigerate ripe tomatoes if you need them to last longer, and refrigerate cut tomatoes in a covered container.';
    }
    if (q.contains('spinach')) {
      return 'Spinach is a leafy green that contributes fiber and nutrients such as folate and vitamin K. Add washed leaves to salads, soups, or a quick sauté.';
    }
    if (q.contains('salad')) {
      return 'Try a colorful bowl of cucumber, tomatoes, grated carrots, and leafy greens. Finish with lemon and olive oil. Add cooked chickpeas if you would like a more filling bowl.';
    }
    if (q.contains('season')) {
      return 'Seasonal produce varies by place and weather. Browse local farm listings and ask your grower what was recently harvested. Our sample catalog includes carrots, tomatoes, and strawberries.';
    }
    return 'I use a small set of prepared answers. Try asking about tomato storage, vitamin C fruits, spinach, salad ideas, available stock, local farmers, or pickup timings.';
  }

  void send(String value) {
    if (value.trim().isEmpty) {
      return;
    }
    setState(() {
      messages.add((user: true, text: value.trim()));
      messages.add((user: false, text: answer(value)));
      input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Farm assistant',
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Surface(
            color: lime,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your pocket-sized produce guide\nPrepared answers · General food information',
                    style: TextStyle(color: green, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              return Align(
                alignment: m.user
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: m.user ? green : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: m.user ? Colors.white : green,
                      height: 1.65,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children:
                [
                      'How to store tomatoes?',
                      'Salad ideas',
                      'What is in stock?',
                      'Pickup timings',
                    ]
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(s),
                          onPressed: () => send(s),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  onSubmitted: send,
                  decoration: const InputDecoration(
                    hintText: 'Ask something fresh…',
                  ),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Send message',
                onPressed: () => send(input.text),
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
