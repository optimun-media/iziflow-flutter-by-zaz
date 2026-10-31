import 'iziflow_customer.dart';

/// Paramètres envoyés à `POST /api/v1/checkout-sessions` pour obtenir
/// la page de paiement hébergée.
///
/// [reference] est la référence unique de la commande côté intégrateur :
/// c'est aussi la clé d'idempotence — renvoyer la même référence avec un
/// montant différent est refusé (409) par le serveur.
class IziflowSessionRequest {
  const IziflowSessionRequest({
    required this.reference,
    required this.amountCents,
    required this.merchantName,
    this.currency = 'CAD',
    this.merchantReference,
    this.customerReference,
    this.customer,
    this.metadata,
  }) : assert(amountCents >= 50, 'amountCents must be >= 50'),
       assert(
         currency == 'CAD' || currency == 'USD',
         'currency must be CAD or USD',
       );

  /// Référence unique de la commande (max 100 caractères).
  final String reference;

  /// Montant en plus petite unité (cents) — minimum 50.
  final int amountCents;

  /// `CAD` ou `USD`.
  final String currency;

  /// Nom affiché « Paiement à … » sur la page hébergée.
  final String merchantName;

  /// Identifiant stable du marchand (client de l'agrégateur). Requis —
  /// avec [customerReference] — pour que le coffre de cartes du client
  /// soit proposé sur la page de paiement.
  final String? merchantReference;

  /// Identifiant du client final chez le marchand. Activé avec
  /// [merchantReference], il débloque les cartes enregistrées et la case
  /// « mémoriser cette carte ».
  final String? customerReference;

  /// Pré-remplissage du formulaire de paiement.
  final IziflowCustomer? customer;

  /// Métadonnées libres, renvoyées au webhook marchand
  /// (`metadata.order_id` est repris dans les URL de retour).
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toJson(String returnUrl, String? cancelUrl) => {
    'reference': reference,
    'amount_cents': amountCents,
    'currency': currency,
    'merchant_name': merchantName,
    'merchant_reference': ?merchantReference,
    'customer_reference': ?customerReference,
    'customer': ?customer?.toJson(),
    'return_url': returnUrl,
    'cancel_url': ?cancelUrl,
    'metadata': ?metadata,
  };
}
