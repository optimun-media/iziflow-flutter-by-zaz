import 'package:flutter/material.dart';
import 'package:iziflow_flutter/iziflow_flutter.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IziFlow Checkout Demo',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF008CFB)),
      home: const CartPage(),
    );
  }
}

/// Panier démo : un bouton « Payer » lance le checkout embarqué.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _status = 'En attente de paiement';
  int _orderSeq = 0;

  Future<void> _pay() async {
    final orderId = 'ORD-${++_orderSeq}';

    final result = await IziflowCheckout.pay(
      context,
      config: const IziflowConfig(
        apiKey: 'iziflow-api-key', // ← votre clé API IziFlow
        // baseUrl: 'https://checkout.iziflow.ca' (défaut production)
      ),
      request: IziflowSessionRequest(
        reference: orderId,
        amountCents: 2500, // 25,00 $
        merchantName: 'Boutique Démo',
        merchantReference: 'boutique-demo',
        customerReference: 'user-42',
        customer: const IziflowCustomer(
          name: 'Jean Dupont',
          email: 'jean@exemple.com',
        ),
        metadata: {'order_id': orderId},
      ),
      // Pages de redirection selon la réponse de l'API :
      onSuccess: (r) => _go(ResultPage(result: r)),
      onDeclined: (r) => _go(ResultPage(result: r)),
      onCancelled: (r) => setState(() => _status = 'Annulé par le client'),
      onError: (r) => setState(() => _status = 'Erreur : ${r.message}'),
    );

    setState(() => _status = 'Résultat : ${result.status.name}');
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Total : 25,00 \$ CAD', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 24),
            FilledButton(onPressed: _pay, child: const Text('Payer')),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.result});

  final IziflowPaymentResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.isSuccess;
    return Scaffold(
      appBar: AppBar(title: Text(ok ? 'Paiement réussi' : 'Paiement refusé')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.error,
              size: 64,
              color: ok ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 16),
            Text('Référence : ${result.reference ?? '—'}'),
            if (result.receiptId != null) Text('Reçu : ${result.receiptId}'),
          ],
        ),
      ),
    );
  }
}
