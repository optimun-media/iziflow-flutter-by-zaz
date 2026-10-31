import 'dart:convert';

import 'package:http/http.dart' as http;

import 'iziflow_config.dart';
import 'iziflow_exception.dart';
import 'models/iziflow_session.dart';
import 'models/iziflow_session_request.dart';

/// Client HTTP minimal pour l'API IziFlow (`/api/v1`).
class IziflowClient {
  IziflowClient(this.config);

  final IziflowConfig config;

  /// Crée une session de paiement hébergée et renvoie l'URL de la page.
  Future<IziflowSession> createSession(IziflowSessionRequest request) async {
    final client = config.httpClient ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse('${config.baseUrl}/api/v1/checkout-sessions'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Admin-Api-Key': config.apiKey,
            },
            body: jsonEncode(
              request.toJson(config.returnUrl, config.cancelUrl),
            ),
          )
          .timeout(config.timeout);

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};

      if (response.statusCode == 409) {
        throw IziflowException(
          body['message'] as String? ??
              'Cette référence a déjà été utilisée avec un autre montant.',
          statusCode: 409,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw IziflowException(
          body['message'] as String? ??
              'Session refusée (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }

      return IziflowSession.fromJson(body);
    } on IziflowException {
      rethrow;
    } on FormatException catch (e) {
      throw IziflowException('Réponse IziFlow invalide : ${e.message}');
    } catch (e) {
      throw IziflowException('API IziFlow injoignable : $e');
    } finally {
      if (config.httpClient == null) client.close();
    }
  }
}
