enum AssetCategory {
  appliance,
  system,
  paint,
  finish,
  document,
  receipt,
  electrical,
  other,
}

class Asset {
  final String id;
  final String homeId;
  final String imagePath;
  final AssetCategory category;
  final String? room;
  final String? notes;

  Asset({
    required this.id,
    required this.homeId,
    required this.imagePath,
    required this.category,
    this.room,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'homeId': homeId,
        'imagePath': imagePath,
        'category': category.name,
        'room': room,
        'notes': notes,
      };

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'],
      homeId: json['homeId'],
      imagePath: json['imagePath'],
      category: AssetCategory.values.firstWhere(
        (e) => e.name == json['category'],
      ),
      room: json['room'],
      notes: json['notes'],
    );
  }
}
  extension AssetCategoryX on AssetCategory {
    bool get isSystem {
      return this == AssetCategory.system ||
            this == AssetCategory.appliance ||
            this == AssetCategory.electrical;
    }

    bool get isFinish {
      return this == AssetCategory.paint ||
            this == AssetCategory.finish;
    }
      String get displayName {
    switch (this) {
      case AssetCategory.appliance:
        return 'Appliances';
      case AssetCategory.system:
        return 'Systems';
      case AssetCategory.paint:
        return 'Paint';
      case AssetCategory.finish:
        return 'Finishes';
      case AssetCategory.electrical:
        return 'Electrical';
      case AssetCategory.receipt:
        return 'Receipt';  
      case AssetCategory.document:
        return 'Documents';
      case AssetCategory.other:
        return 'Other';

    }
  }
}