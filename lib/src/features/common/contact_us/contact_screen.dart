part of '../profile/profile.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), message = TextEditingController();
  bool sent = false;
  @override
  void dispose() {
    email.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Get in touch',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Harvest.colors(context).green.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Harvest.colors(context).green.withValues(alpha: .15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 34,
                  color: Harvest.colors(context).green,
                ),
                const SizedBox(height: 14),
                Text('We’re all ears.', style: Harvest.editorial(32)),
                const SizedBox(height: 8),
                Text(
                  'A question, an idea, or something we could do better? We’d love to hear from you.',
                  style: TextStyle(
                    color: Harvest.colors(context).muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const PublishedContent(contact: true),
          const SectionHeader('Send us a message'),
          HarvestField(
            controller: email,
            label: 'Your email address',
            keyboard: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          const SizedBox(height: 16),
          HarvestField(controller: message, label: 'Your message', lines: 5),
          const SizedBox(height: 24),
          HarvestButton(
            label: 'Send feedback',
            icon: Icons.arrow_forward,
            onPressed: HarvestScope.of(context).busy || sent
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    final result = await HarvestScope.of(context)
                        .sendFeedback(email.text, message.text);
                    if (!context.mounted) return;
                    if (result != null) {
                      notice(context, result, isError: true);
                    } else {
                      setState(() => sent = true);
                    }
                  },
          ),
          if (sent) ...[
            const SizedBox(height: 24),
            const InfoNote('Thank you. Your feedback has been saved.'),
          ],
        ],
      ),
    ),
  );
}
