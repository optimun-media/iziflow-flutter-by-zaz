/// Session de paiement créée par `POST /api/v1/checkout-sessions`.
class IziflowSession {
  const IziflowSession({
    required this.reference,
    required this.paymentUrl,
    this.status,
    this.expiresAt,
  });

  final String reference;

  /// URL de la page de paiement hébergée — ouverte dans le WebView du SDK.
  final Uri paymentUrl;

  /// `open` à la création.
  final String? status;

  /// Expiration de la page (typiquement 30 min).
  final DateTime? expiresAt;

  factory IziflowSession.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? json;
    final url = data['payment_url'];

    if (url is! String || url.isEmpty) {
      throw const FormatException('payment_url missing in session response');
    }

    return IziflowSession(
      reference: data['reference'] as String? ?? '',
      paymentUrl: Uri.parse(url),
      status: data['status'] as String?,
      expiresAt: data['expires_at'] is String
          ? DateTime.tryParse(data['expires_at'] as String)
          : null,
    );
  }
}
