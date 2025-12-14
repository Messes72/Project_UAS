class BookingModel {
  final String id;
  final String fieldId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final double totalPrice;
  final String? proofOfPaymentUrl;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.fieldId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    this.proofOfPaymentUrl,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      fieldId: json['field_id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'],
      totalPrice: (json['total_price'] as num).toDouble(),
      proofOfPaymentUrl: json['proof_of_payment_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field_id': fieldId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status,
      'total_price': totalPrice,
      if (proofOfPaymentUrl != null) 'proof_of_payment_url': proofOfPaymentUrl,
    };
  }
}
