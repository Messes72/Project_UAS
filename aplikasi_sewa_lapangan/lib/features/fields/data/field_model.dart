class FieldModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final double pricePerHour;
  final String address;
  final double? lat;
  final double? lng;
  final bool isActive;
  final DateTime createdAt;
  final List<String> images;
  final List<String> facilities;

  FieldModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.pricePerHour,
    required this.address,
    this.lat,
    this.lng,
    required this.isActive,
    required this.createdAt,
    this.images = const [],
    required this.facilities,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      description: json['description'],
      pricePerHour: (json['price_per_hour'] as num).toDouble(),
      address: json['address'],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      facilities: json['facilities'] != null 
          ? List<String>.from(json['facilities']) 
          : [], 
      images:
          (json['field_images'] as List<dynamic>?)
              ?.map((e) => e['file_path'] as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (description != null) 'description': description,
      'name': name,
      'price_per_hour': pricePerHour,
      'address': address,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'is_active': isActive,
      'facilities': facilities,
    };
  }
}
