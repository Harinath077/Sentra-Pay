class ReceiverInfo {
  final String upiId;
  final String name;
  final String? bank;
  final bool verified;
  final double reputationScore;
  
  // 🔥 New Fields
  final int riskScore;
  final String riskLevel;
  final List<String> riskFactors;
  final String? microTip;

  final String? icon;
  final String? color;
  final String? background;
  final String? label;

  ReceiverInfo({
    required this.upiId,
    required this.name,
    this.bank,
    required this.verified,
    this.reputationScore = 0.5,
    this.riskScore = 0,
    this.riskLevel = "Low",
    this.riskFactors = const [],
    this.microTip,
    this.icon,
    this.color,
    this.background,
    this.label,
  });

  factory ReceiverInfo.fromJson(Map<String, dynamic> json) {
    return ReceiverInfo(
      upiId: json['vpa'] ?? json['upi_id'] ?? '',
      name: json['name'] ?? 'Unknown Receiver',
      bank: json['bank'],
      verified: json['verified'] ?? false,
      reputationScore: (json['reputation_score'] ?? 0.5).toDouble(),
      riskScore: json['risk_score'] ?? 0,
      riskLevel: json['risk_level'] ?? "Low",
      riskFactors: List<String>.from(json['risk_factors'] ?? []),
      microTip: json['micro_tip'],
      icon: json['icon'],
      color: json['color'],
      background: json['background'],
      label: json['label'],
    );
  }
}
