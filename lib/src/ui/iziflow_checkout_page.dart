import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../iziflow_return_parser.dart';
import '../models/iziflow_payment_result.dart';
import '../models/iziflow_session.dart';

/// Page de paiement IziFlow affichée en plein écran dans l'app hôte.
///
/// Charge la page hébergée (saisie carte + authentification 3-D Secure
/// chez la banque) sans jamais ouvrir de navigateur externe. Toute
/// navigation vers la `return_url`/`cancel_url` de la session est
/// interceptée et convertie en [IziflowPaymentResult] — renvoyé via
/// `Navigator.pop`, ce qui laisse l'intégrateur libre de sa navigation.
///
/// L'API de retour est un `Future<IziflowPaymentResult>` :
/// `Navigator.push<IziflowPaymentResult>(...)`.
class IziflowCheckoutPage extends StatefulWidget {
  const IziflowCheckoutPage({
    super.key,
    required this.session,
    required this.parser,
    this.title = 'Paiement sécurisé',
  });

  final IziflowSession session;
  final IziflowReturnParser parser;

  /// Titre de la barre du haut.
  final String title;

  @override
  State<IziflowCheckoutPage> createState() => _IziflowCheckoutPageState();
}

class _IziflowCheckoutPageState extends State<IziflowCheckoutPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Fin du parcours : le serveur redirige vers les URL de retour —
            // on les intercepte, elles ne doivent jamais se charger.
            final result = widget.parser.parse(request.url);
            if (result != null) {
              _finish(result);
              return NavigationDecision.prevent;
            }

            // Tout reste dans le WebView : les schemes externes
            // (tel:, mailto:, apps bancaires…) sont bloqués, tout comme
            // le non-HTTPS (les pages bancaires 3DS sont en https).
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(widget.session.paymentUrl);
  }

  void _finish(IziflowPaymentResult result) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(result);
  }

  void _abort() => _finish(
    const IziflowPaymentResult(status: IziflowCheckoutStatus.aborted),
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop reste false tant que le SDK termine lui-même (_finish) ;
      // sinon Navigator.pop serait intercepté comme un retour utilisateur.
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _abort();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _abort,
            tooltip: 'Fermer',
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: _loading
                ? const LinearProgressIndicator(minHeight: 2)
                : const SizedBox(height: 2),
          ),
        ),
        body: SafeArea(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
