import 'dart:math';

class UserProfile {
  final String userId;
  final String securityId;
  final String fullName;
  final String email;
  final String? mobile;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final int transactionCount;
  final double trustScore;
  final String deviceId;
  final int loginCount;
  final List<String> commonVPAs;

  UserProfile({
    required this.userId,
    required this.securityId,
    required this.fullName,
    required this.email,
    this.mobile,
    this.profilePhotoUrl,
    required this.createdAt,
    this.transactionCount = 0,
    this.trustScore = 100.0,
    required this.deviceId,
    this.loginCount = 1,
    this.commonVPAs = const [],
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? mobile,
    String? profilePhotoUrl,
    int? transactionCount,
    double? trustScore,
    int? loginCount,
    List<String>? commonVPAs,
  }) {
    return UserProfile(
      userId: userId,
      securityId: securityId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt,
      transactionCount: transactionCount ?? this.transactionCount,
      trustScore: trustScore ?? this.trustScore,
      deviceId: deviceId,
      loginCount: loginCount ?? this.loginCount,
      commonVPAs: commonVPAs ?? this.commonVPAs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'securityId': securityId,
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': createdAt.toIso8601String(),
      'transactionCount': transactionCount,
      'trustScore': trustScore,
      'deviceId': deviceId,
      'loginCount': loginCount,
      'commonVPAs': commonVPAs,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] ?? json['userId'] ?? 'USER-UNKNOWN',
      securityId: json['security_id'] ?? json['securityId'] ?? (json['user_id'] ?? 'UNKNOWN').toString().substring(0, min(8, (json['user_id'] ?? 'UNKNOWN').toString().length)),
      fullName: json['full_name'] ?? json['fullName'] ?? 'User',
      email: json['email'] ?? '',
      mobile: json['phone'] ?? json['mobile'],
      profilePhotoUrl: json['profile_photo_url'] ?? json['profilePhotoUrl'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      transactionCount: json['transaction_count'] ?? json['transactionCount'] ?? 0,
      trustScore: (json['trust_score'] ?? json['trustScore'] ?? 100.0).toDouble(),
      deviceId: json['device_id'] ?? json['deviceId'] ?? 'DEV-${Random().nextInt(9999).toString().padLeft(4, '0')}',
      loginCount: json['login_count'] ?? json['loginCount'] ?? 1,
      commonVPAs: List<String>.from(json['common_vpas'] ?? json['commonVPAs'] ?? []),
    );
  }
}
