/// Issue possible d'un checkout IziFlow.
enum IziflowCheckoutStatus {
  /// Le paiement a été accepté (param `status=success` sur la return_url).
  success,

  /// Le paiement a été refusé par la banque (`status=failed`).
  declined,

  /// Le client a annulé via la cancel_url.
  cancelled,

  /// Le client a fermé la page avant la fin, sans action explicite.
  aborted,

  /// Erreur technique : API injoignable, session refusée, réponse invalide.
  error,
}

/// Résultat final renvoyé par [IziflowCheckout.pay] et passé aux
/// callbacks `onSuccess` / `onDeclined` / `onCancelled` / `onError`.
class IziflowPaymentResult {
  const IziflowPaymentResult({
    required this.status,
    this.reference,
    this.orderId,
    this.receiptId,
    this.message,
  });

  final IziflowCheckoutStatus status;

  /// Référence IziFlow de la session (celle envoyée à la création).
  final String? reference;

  /// `metadata.order_id` renvoyé par la return_url, si fourni.
  final String? orderId;

  /// `paymentId` Moneris en cas de succès — preuve de paiement.
  final String? receiptId;

  /// Détail d'erreur éventuel.
  final String? message;

  bool get isSuccess => status == IziflowCheckoutStatus.success;
}
