class ScanResult {
  final String message;
  final String analysis;
  final bool isScam;
  final String scamType;
  final String riskLevel;
  final double confidence;
  final String category;

  const ScanResult({
    required this.message,
    required this.analysis,
    required this.isScam,
    required this.scamType,
    required this.riskLevel,
    required this.confidence,
    required this.category,
  });

  factory ScanResult.fromJson({
    required Map<String, dynamic> json,
    required String originalMessage,
  }) {
    final dynamic rawConfidence = json['confidence'];

    double confidence = 0.0;

    if (rawConfidence is num) {
      confidence = rawConfidence.toDouble();

      // Support both:
      // 0.95  -> 95%
      // 95    -> 95%
      if (confidence <= 1.0) {
        confidence *= 100.0;
      }
    }

    confidence = confidence.clamp(0.0, 100.0);

    return ScanResult(
      message:
          json['message']?.toString() ?? originalMessage,

      analysis:
          json['analysis']?.toString() ??
              'No detailed analysis was returned.',

      isScam:
          json['is_scam'] == true,

      scamType:
          json['scam_type']?.toString() ??
              'Suspicious Message',

      riskLevel:
          json['risk_level']?.toString() ??
              'LOW',

      confidence: confidence,

      category:
          json['category']?.toString() ??
              'Suspicious Content',
    );
  }
}