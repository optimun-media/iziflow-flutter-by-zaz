import 'package:http/http.dart' as http;

/// Configuration globale du SDK IziFlow.
///
/// [returnUrl] et [cancelUrl] sont les URL que le serveur de paiement
/// utilise pour signaler la fin du paiement. Elles ne sont jamais ouvertes :
/// le SDK les intercepte dans le WebView et les traduit en résultat.
/// Leur domaine DOIT être autorisé côté serveur
/// (`MONERIS_ALLOWED_RETURN_HOSTS`) — par défaut `iziflow.ca`.
class IziflowConfig {
  const IziflowConfig({
    required this.apiKey,
    this.baseUrl = 'https://checkout.iziflow.ca',
    this.returnUrl = 'https://iziflow.ca/iziflow-checkout/return',
    this.cancelUrl = 'https://iziflow.ca/iziflow-checkout/cancel',
    this.timeout = const Duration(seconds: 30),
    this.httpClient,
  });

  /// Clé API interne IziFlow (header `X-Admin-Api-Key`).
  final String apiKey;

  /// Racine du service de checkout (sans slash final).
  final String baseUrl;

  /// URL interceptée en fin de paiement réussi ou refusé.
  final String returnUrl;

  /// URL interceptée quand le client annule.
  final String cancelUrl;

  /// Timeout des appels HTTP vers l'API IziFlow.
  final Duration timeout;

  /// Client HTTP injectable (tests, proxy…).
  final http.Client? httpClient;
}
