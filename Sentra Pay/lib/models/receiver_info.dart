class ReceiverInfo {
  final String upiId;
  final String name;
  final String? bank;
  final bool verified;
  final double reputationScore;

  ReceiverInfo({
    required this.upiId,
    required this.name,
    this.bank,
    required this.verified,
    this.reputationScore = 0.5,
  });

  factory ReceiverInfo.fromJson(Map<String, dynamic> json) {
    return ReceiverInfo(
      upiId: json['vpa'] ?? json['upi_id'] ?? '',
      name: json['name'] ?? 'Unknown Receiver',
      bank: json['bank'],
      verified: json['verified'] ?? false,
      reputationScore: (json['reputation_score'] ?? 0.5).toDouble(),
    );
  }
}
