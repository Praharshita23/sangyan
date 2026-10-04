import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sangyan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Stay safe from scams',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Sangyan helps you identify suspicious '
                'messages and common scam patterns.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/scan',
                    );
                  },
                  icon: const Icon(
                    Icons.search,
                  ),
                  label: const Text(
                    'Scan a Message',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'What Sangyan can check',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _DetectionCard(
                icon: Icons.link,
                title: 'Suspicious Links',
                description:
                    'Identify phishing and malicious-link patterns.',
              ),

              _DetectionCard(
                icon: Icons.account_balance,
                title: 'Bank & OTP Scams',
                description:
                    'Detect requests for OTPs, PINs and banking details.',
              ),

              _DetectionCard(
                icon: Icons.payment,
                title: 'Payment Scams',
                description:
                    'Detect suspicious payment and money-transfer requests.',
              ),

              _DetectionCard(
                icon: Icons.card_giftcard,
                title: 'Prize & Lottery Scams',
                description:
                    'Identify fake winnings and reward scams.',
              ),

              _DetectionCard(
                icon: Icons.warning_amber_rounded,
                title: 'Urgent / Social Engineering',
                description:
                    'Detect pressure tactics and suspicious requests.',
              ),

              _DetectionCard(
                icon: Icons.manage_accounts,
                title: 'Account / KYC Scams',
                description:
                    'Identify suspicious account-verification requests.',
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Never share OTPs, passwords, '
                        'UPI PINs or banking details with anyone.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DetectionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.deepPurple.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}