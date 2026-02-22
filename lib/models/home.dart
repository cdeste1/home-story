class Home {
  final String id;
  final String address;
  final DateTime createdAt;

  // Optional metadata (future-proofed)
  final int? yearBuilt;
  final int? squareFeet;  
  final String? utilities;
  final String? hoaInfo;
  final String? exteriorImagePath;

  Home({
    required this.id,
    required this.address,
    required this.createdAt,
    this.yearBuilt,
    this.squareFeet,
    this.utilities,
    this.hoaInfo,
    this.exteriorImagePath,
  });

  Home copyWith({
  String? id,
  String? address,
  DateTime? createdAt,
  int? yearBuilt,
  int? squareFeet,
  String? utilities,
  String? hoaInfo,
  String? exteriorImagePath,
}) {
  return Home(
    id: id ?? this.id,
    address: address ?? this.address,
    createdAt: createdAt ?? this.createdAt,
    yearBuilt: yearBuilt ?? this.yearBuilt,
    squareFeet: squareFeet ?? this.squareFeet,
    utilities: utilities ?? this.utilities,
    hoaInfo: hoaInfo ?? this.hoaInfo,
    exteriorImagePath: exteriorImagePath ?? this.exteriorImagePath,
  );
}

  factory Home.fromJson(Map<String, dynamic> json) {
    return Home(
      id: json['id'],
      address: json['address'],
      createdAt: DateTime.parse(json['createdAt']),
      yearBuilt: json['yearBuilt'],
      squareFeet: json['squareFeet'],
      utilities: json['utilities'],
      hoaInfo: json['hoaInfo'],
      exteriorImagePath: json['exteriorImagePath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'yearBuilt': yearBuilt,
      'squareFeet': squareFeet,
      'utilities': utilities,
      'hoaInfo': hoaInfo,
      'exteriorImagePath': exteriorImagePath,
    };
  }
}