/// IziFlow Checkout for Flutter.
///
/// Embeds the hosted IziFlow checkout inside an integrator app: the end
/// customer pays by card (mobile money support planned) without ever
/// leaving the app. Card data is collected exclusively inside the IziFlow
/// hosted page — it never transits through the integrator app.
///
/// Basic usage:
/// ```dart
/// final result = await IziflowCheckout.pay(
///   context,
///   config: IziflowConfig(apiKey: 'your-api-key'),
///   request: IziflowSessionRequest(
///     reference: 'ORDER-123',
///     amountCents: 2500,
///     merchantName: 'Boutique ABC',
///   ),
///   onSuccess: (r) => Navigator.push(context, successRoute),
///   onDeclined: (r) => Navigator.push(context, failedRoute),
///   onCancelled: (r) => Navigator.pop(context),
/// );
/// ```
library;

export 'src/iziflow_checkout.dart';
export 'src/iziflow_client.dart';
export 'src/iziflow_config.dart';
export 'src/iziflow_exception.dart';
export 'src/models/iziflow_customer.dart';
export 'src/models/iziflow_payment_result.dart';
export 'src/models/iziflow_session.dart';
export 'src/models/iziflow_session_request.dart';
export 'src/ui/iziflow_checkout_page.dart';
