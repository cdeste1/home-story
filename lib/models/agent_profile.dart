class AgentProfile {
  final String name;
  final String brokerage;
  final String? email;
  final String? phone;
  final int? accentColor; // ← NEW (ARGB int)
  final String? logoPath; // optional local path to logo image

  AgentProfile({
    required this.name,
    required this.brokerage,
    this.email,
    this.phone,
    this.accentColor,
    this.logoPath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'brokerage': brokerage,
        'email': email,
        'phone': phone,
        'accent': accentColor,
        'logopath': logoPath,
        
      };

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    return AgentProfile(
      name: json['name'],
      brokerage: json['brokerage'],
      email: json['email'],
      phone: json['phone'],
      accentColor: json['accent'],
      logoPath: json['logopath'],
    );
  }
}
