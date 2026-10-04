import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String message;
  final String analysis;
  final bool isScam;
  final String scamType;
  final String riskLevel;
  final double confidence;
  final String category;

  const ResultScreen({
    super.key,
    required this.message,
    required this.analysis,
    required this.isScam,
    required this.scamType,
    required this.riskLevel,
    required this.confidence,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final Color resultColor = isScam
        ? Colors.red
        : Colors.green;

    final String resultTitle = isScam
        ? 'Potential Scam Detected'
        : 'Message Appears Safe';

    final double normalizedConfidence =
        confidence > 1
            ? confidence / 100
            : confidence;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Result',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isScam
                  ? Icons.warning_amber_rounded
                  : Icons.verified,
              size: 80,
              color: resultColor,
            ),

            const SizedBox(height: 16),

            Text(
              resultTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),

            const SizedBox(height: 24),

            _infoCard(
              context,
              'Risk Level',
              riskLevel,
            ),

            _infoCard(
              context,
              'Scam Type',
              scamType,
            ),

            _infoCard(
              context,
              'Category',
              category,
            ),

            _infoCard(
              context,
              'Confidence',
              '${(normalizedConfidence * 100).toStringAsFixed(1)}%',
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      analysis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanned Content',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      message,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Scan Another',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    String title,
    String value,
  ) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}