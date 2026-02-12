import 'dart:math';

/// Micro-tips for fraud awareness
/// Shows educational tips to users throughout the app
class MicroTips {
  static final Random _random = Random();

  // Categorized tips
  static const List<String> _generalTips = [
    '💡 Banks never ask you to send money urgently',
    '💡 Scammers create fake urgency - stay calm',
    '💡 Always verify the receiver before paying',
    '💡 Double-check UPI IDs letter by letter',
    '💡 If something feels wrong, trust your instinct',
  ];

  static const List<String> _scamAwarenessTips = [
    '🚨 "KYC update required" messages are usually scams',
    '🚨 No one from a bank will ask for OTP over call',
    '🚨 Government refunds never come via UPI requests',
    '🚨 Prize/lottery UPIs are 100% fraudulent',
    '🚨 Verify job offers before paying "registration fees"',
  ];

  static const List<String> _bestPracticesTips = [
    '✅ Save frequent contacts for quick verification',
    '✅ Enable transaction limits in your bank app',
    '✅ Check your transaction history regularly',
    '✅ Report suspicious UPI IDs immediately',
    '✅ Use official apps only for payments',
  ];

  static const List<String> _privacyTips = [
    '🔒 Never share your UPI PIN with anyone',
    '🔒 Keep your phone number private',
    '🔒 Don\'t accept money from unknown sources',
    '🔒 Avoid public WiFi for transactions',
    '🔒 Enable screen lock on your device',
  ];

  // Get a random tip from all categories
  static String getRandomTip() {
    final allTips = [
      ..._generalTips,
      ..._scamAwarenessTips,
      ..._bestPracticesTips,
      ..._privacyTips,
    ];
    return allTips[_random.nextInt(allTips.length)];
  }

  // Get a tip from specific category
  static String getTipByCategory(TipCategory category) {
    List<String> tips;
    switch (category) {
      case TipCategory.general:
        tips = _generalTips;
        break;
      case TipCategory.scamAwareness:
        tips = _scamAwarenessTips;
        break;
      case TipCategory.bestPractices:
        tips = _bestPracticesTips;
        break;
      case TipCategory.privacy:
        tips = _privacyTips;
        break;
    }
    return tips[_random.nextInt(tips.length)];
  }

  // Get contextual tip based on risk score
  static String getContextualTip(double riskScore) {
    if (riskScore >= 0.7) {
      // High risk - show scam awareness
      return getTipByCategory(TipCategory.scamAwareness);
    } else if (riskScore >= 0.4) {
      // Medium risk - show best practices
      return getTipByCategory(TipCategory.bestPractices);
    } else {
      // Low risk - show general or privacy tips
      return _random.nextBool()
          ? getTipByCategory(TipCategory.general)
          : getTipByCategory(TipCategory.privacy);
    }
  }

  // Get multiple tips (e.g., for tips page)
  static List<String> getMultipleTips(int count) {
    final allTips = [
      ..._generalTips,
      ..._scamAwarenessTips,
      ..._bestPracticesTips,
      ..._privacyTips,
    ];
    
    // Shuffle and return requested count
    final shuffled = List<String>.from(allTips)..shuffle();
    return shuffled.take(count).toList();
  }

  // Get "Did you know?" fact
  static String getDidYouKnow() {
    final facts = [
      '📊 Over 95% of UPI frauds involve social engineering',
      '📊 Scammers target emotional triggers like fear and greed',
      '📊 Most frauds happen when users share OTP/PIN',
      '📊 Unknown sender requests are red flags',
      '📊 Legitimate businesses never ask for upfront UPI payments',
    ];
    return facts[_random.nextInt(facts.length)];
  }
}

enum TipCategory {
  general,
  scamAwareness,
  bestPractices,
  privacy,
}
