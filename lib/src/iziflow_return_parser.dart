import 'models/iziflow_payment_result.dart';

/// Traduit la navigation du WebView en résultat de checkout.
///
/// Le serveur redirige vers `returnUrl` (`status=success|failed`) ou
/// `cancelUrl` (`status=cancelled`) à la fin du paiement. Le SDK
/// intercepte ces URL — elles ne s'ouvrent jamais.
class IziflowReturnParser {
  const IziflowReturnParser({required this.returnUrl, required this.cancelUrl});

  final String returnUrl;
  final String cancelUrl;

  /// `null` si [url] n'est ni la return_url ni la cancel_url.
  IziflowPaymentResult? parse(String url) {
    if (url.startsWith(returnUrl)) {
      return _result(url, isCancel: false);
    }
    if (url.startsWith(cancelUrl)) {
      return _result(url, isCancel: true);
    }
    return null;
  }

  IziflowPaymentResult _result(String url, {required bool isCancel}) {
    final params = Uri.tryParse(url)?.queryParameters ?? const {};
    final status = params['status'];

    final checkoutStatus = isCancel
        ? IziflowCheckoutStatus.cancelled
        : status == 'success'
        ? IziflowCheckoutStatus.success
        : IziflowCheckoutStatus.declined;

    return IziflowPaymentResult(
      status: checkoutStatus,
      reference: params['reference'],
      orderId: params['order_id'],
      receiptId: params['receipt'],
    );
  }
}
