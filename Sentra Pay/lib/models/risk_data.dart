class RiskData {
  final double score;
  final String status;
  final List<String> explanations;

  RiskData({
    required this.score,
    required this.status,
    required this.explanations,
  });

  factory RiskData.mock(bool isRisky) {
    if (isRisky) {
      return RiskData(
        score: 0.85,
        status: 'Blocked',
        explanations: [
          'Unusual large amount for this time',
          'Receiver location mismatch',
          'New device used for transaction',
        ],
      );
    } else {
      return RiskData(
        score: 0.15,
        status: 'Approved',
        explanations: [
          'Frequent transaction partner',
          'Device matches history',
          'Location verified',
        ],
      );
    }
  }
}
