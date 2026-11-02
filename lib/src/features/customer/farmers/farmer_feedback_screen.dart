part of '../customer.dart';

class FarmerFeedbackScreen extends StatefulWidget {
  const FarmerFeedbackScreen({
    super.key,
    required this.farmId,
    required this.farmName,
  });
  final String farmId, farmName;

  @override
  State<FarmerFeedbackScreen> createState() => _FarmerFeedbackScreenState();
}

class _FarmerFeedbackScreenState extends State<FarmerFeedbackScreen> {
  final form = GlobalKey<FormState>();
  final message = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (!form.currentState!.validate()) return;
    final account = HarvestScope.of(context).account;
    setState(() => sending = true);
    try {
      await FirebaseFirestore.instance.collection('farmerFeedback').add({
        'farmId': widget.farmId,
        'customerId': account.id,
        'name': account.name,
        'email': account.email,
        'message': message.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        message.clear();
        notice(context, 'Feedback sent to the farmer and administrator.');
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Could not send feedback. Please retry.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Feedback for ${widget.farmName}')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Share your experience with this farmer.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: message,
            maxLines: 5,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'Your feedback',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'Enter your feedback.' : null,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: sending ? null : send,
            child: Text(sending ? 'Sending…' : 'Send feedback'),
          ),
        ],
      ),
    ),
  );
}

class FarmerFeedbackList extends StatelessWidget {
  const FarmerFeedbackList({super.key, this.farmId});
  final String? farmId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Farmer feedback')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream:
          (farmId == null
                  ? FirebaseFirestore.instance.collection('farmerFeedback')
                  : FirebaseFirestore.instance
                        .collection('farmerFeedback')
                        .where('farmId', isEqualTo: farmId))
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load feedback.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final first = a.data()['createdAt'] as Timestamp?;
            final second = b.data()['createdAt'] as Timestamp?;
            return (second?.seconds ?? 0).compareTo(first?.seconds ?? 0);
          });
        if (rows.isEmpty) {
          return const Center(child: Text('No farmer feedback yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final data = rows[index].data();
            return Card(
              child: ListTile(
                title: Text(data['name'] as String? ?? 'Customer'),
                subtitle: Text(
                  '${data['message'] ?? ''}\n${data['email'] ?? ''}',
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    ),
  );
}
