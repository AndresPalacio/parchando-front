class ItemParticipant {
  final String userId; // Internamente usamos userId, pero al backend enviamos friend_id
  final double share;
  final String shareType; // Internamente usamos shareType, pero al backend enviamos share_type
  final bool paid;
  final double paidAmount; // Internamente usamos paidAmount, pero al backend enviamos paid_amount

  ItemParticipant({
    required this.userId,
    required this.share,
    this.shareType = 'equal',
    this.paid = false,
    this.paidAmount = 0.0,
  });

  factory ItemParticipant.fromJson(Map<String, dynamic> json) {
    // Helper para parsear números que pueden venir como string o num
    double _parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }
    
    // El backend puede enviar friend_id o userId
    final userIdValue = json['friend_id'] ?? json['userId'];
    // El backend puede enviar share_type o shareType
    final shareTypeValue = json['share_type'] ?? json['shareType'] ?? 'equal';
    // El backend puede enviar paid_amount o paidAmount
    final paidAmountValue = json['paid_amount'] ?? json['paidAmount'];
    
    return ItemParticipant(
      userId: userIdValue as String,
      share: _parseDouble(json['share']),
      shareType: shareTypeValue as String,
      paid: json['paid'] as bool? ?? false,
      paidAmount: _parseDouble(paidAmountValue),
    );
  }

  Map<String, dynamic> toJson() {
    // El backend espera friend_id, share_type, paid_amount
    return {
      'friend_id': userId, // Mapear userId a friend_id para el backend
      'share': share,
      'share_type': shareType, // Mapear shareType a share_type para el backend
      'paid': paid,
      'paid_amount': paidAmount, // Mapear paidAmount a paid_amount para el backend
    };
  }
}

