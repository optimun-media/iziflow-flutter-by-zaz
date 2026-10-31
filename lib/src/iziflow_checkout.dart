import 'package:flutter/material.dart';

import 'iziflow_client.dart';
import 'iziflow_config.dart';
import 'iziflow_exception.dart';
import 'iziflow_return_parser.dart';
import 'models/iziflow_payment_result.dart';
import 'models/iziflow_session_request.dart';
import 'ui/iziflow_checkout_page.dart';

/// Point d'entrée du checkout IziFlow.
///
/// [pay] enchaîne : création de la session côté API → ouverture du
/// checkout embarqué → résultat typé dispatché vers le callback
/// correspondant (`onSuccess`, `onDeclined`, `onCancelled`, `onError`).
///
/// Les callbacks sont l'endroit où l'intégrateur redirige vers ses
/// propres pages (succès, échec, retour panier…). Le [Future] renvoyé
/// contient le même résultat pour ceux qui préfèrent `await` + `Navigator`.
class IziflowCheckout {
  IziflowCheckout._();

  /// Lance un paiement par carte dans un checkout embarqué à l'app.
  ///
  /// Exemple :
  /// ```dart
  /// final result = await IziflowCheckout.pay(
  ///   context,
  ///   config: IziflowConfig(apiKey: 'iziflow-api-key'),
  ///   request: IziflowSessionRequest(
  ///     reference: 'ORDER-123',
  ///     amountCents: 2500,
  ///     merchantName: 'Boutique ABC',
  ///   ),
  ///   onSuccess: (r) => Navigator.pushReplacement(
  ///     context, MaterialPageRoute(builder: (_) => SuccessPage(r))),
  ///   onDeclined: (r) => Navigator.pushReplacement(
  ///     context, MaterialPageRoute(builder: (_) => FailedPage(r))),
  ///   onCancelled: (_) {}, // retour silencieux au panier
  /// );
  /// ```
  static Future<IziflowPaymentResult> pay(
    BuildContext context, {
    required IziflowConfig config,
    required IziflowSessionRequest request,
    String title = 'Paiement sécurisé',
    void Function(IziflowPaymentResult result)? onSuccess,
    void Function(IziflowPaymentResult result)? onDeclined,
    void Function(IziflowPaymentResult result)? onCancelled,
    void Function(IziflowPaymentResult result)? onError,
  }) async {
    final client = IziflowClient(config);
    final parser = IziflowReturnParser(
      returnUrl: config.returnUrl,
      cancelUrl: config.cancelUrl,
    );

    IziflowPaymentResult result;

    try {
      final session = await client.createSession(request);

      if (!context.mounted) {
        return const IziflowPaymentResult(
          status: IziflowCheckoutStatus.aborted,
          message: 'Le contexte a été démonté avant ouverture du checkout.',
        );
      }

      final checkoutResult = await Navigator.of(context)
          .push<IziflowPaymentResult>(
            MaterialPageRoute(
              builder: (_) => IziflowCheckoutPage(
                session: session,
                parser: parser,
                title: title,
              ),
            ),
          );

      // Pop sans résultat (geste système non intercepté) → aborted.
      result =
          checkoutResult ??
          const IziflowPaymentResult(status: IziflowCheckoutStatus.aborted);
    } on IziflowException catch (e) {
      result = IziflowPaymentResult(
        status: IziflowCheckoutStatus.error,
        reference: request.reference,
        message: e.message,
      );
    }

    if (!context.mounted) return result;

    switch (result.status) {
      case IziflowCheckoutStatus.success:
        onSuccess?.call(result);
      case IziflowCheckoutStatus.declined:
        onDeclined?.call(result);
      case IziflowCheckoutStatus.cancelled:
      case IziflowCheckoutStatus.aborted:
        onCancelled?.call(result);
      case IziflowCheckoutStatus.error:
        onError?.call(result);
    }

    return result;
  }
}
