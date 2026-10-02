import 'package:flutter/material.dart';

class SubscriptionAccessScreen extends StatefulWidget {
  final Widget dashboard;

  const SubscriptionAccessScreen({
    super.key,
    required this.dashboard,
  });

  @override
  State<SubscriptionAccessScreen> createState() =>
      _SubscriptionAccessScreenState();
}

class _SubscriptionAccessScreenState
    extends State<SubscriptionAccessScreen> {
  bool _loading = false;

  Future<void> _startTrial() async {
    setState(() {
      _loading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.dashboard,
      ),
    );
  }

  Future<void> _subscribe() async {
    setState(() {
      _loading = true;
    });

    // Hapa ndipo payment system itaunganishwa.
    // Kwa sasa tunaendelea kama subscription imekubaliwa.

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.dashboard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Access'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.workspace_premium,
                size: 80,
              ),

              const SizedBox(height: 20),

              const Text(
                'Access MShop Dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Choose one option below to continue to your dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'FREE TRIAL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Start your trial and access the dashboard.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _startTrial,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('START FREE TRIAL'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'SUBSCRIPTION',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Subscribe and continue to the dashboard.',
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _loading ? null : _subscribe,
                          child: const Text('SUBSCRIBE / PAY'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              const Text(
                'You must choose Trial or Subscription before accessing the dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}