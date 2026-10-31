import 'package:flutter_test/flutter_test.dart';
import 'package:iziflow_flutter/iziflow_flutter.dart';
import 'package:iziflow_flutter/src/iziflow_return_parser.dart';

void main() {
  const parser = IziflowReturnParser(
    returnUrl: 'https://iziflow.ca/iziflow-checkout/return',
    cancelUrl: 'https://iziflow.ca/iziflow-checkout/cancel',
  );

  group('IziflowReturnParser', () {
    test('return_url success → success avec reference/orderId/receipt', () {
      final result = parser.parse(
        'https://iziflow.ca/iziflow-checkout/return?status=success'
        '&order_id=ORD-9&reference=IZF-1&receipt=pay_abc',
      );

      expect(result!.status, IziflowCheckoutStatus.success);
      expect(result.reference, 'IZF-1');
      expect(result.orderId, 'ORD-9');
      expect(result.receiptId, 'pay_abc');
      expect(result.isSuccess, isTrue);
    });

    test('return_url failed → declined', () {
      final result = parser.parse(
        'https://iziflow.ca/iziflow-checkout/return?status=failed&reference=IZF-1',
      );

      expect(result!.status, IziflowCheckoutStatus.declined);
      expect(result.isSuccess, isFalse);
    });

    test('cancel_url → cancelled', () {
      final result = parser.parse(
        'https://iziflow.ca/iziflow-checkout/cancel?status=cancelled&reference=IZF-1',
      );

      expect(result!.status, IziflowCheckoutStatus.cancelled);
    });

    test('URL étrangère → null (navigation normale dans le WebView)', () {
      expect(parser.parse('https://acs.bank.example/challenge'), isNull);
      expect(parser.parse('https://checkout.iziflow.ca/checkout/tok'), isNull);
    });
  });

  group('IziflowSessionRequest', () {
    test('toJson mappe le schéma attendu par POST /checkout-sessions', () {
      const request = IziflowSessionRequest(
        reference: 'ORD-123',
        amountCents: 2500,
        merchantName: 'Boutique ABC',
        merchantReference: 'boutique-abc',
        customerReference: 'user-4521',
        customer: IziflowCustomer(email: 'jean@ex.com'),
        metadata: {'order_id': '123'},
      );

      final json = request.toJson(
        'https://iziflow.ca/r',
        'https://iziflow.ca/c',
      );

      expect(json['reference'], 'ORD-123');
      expect(json['amount_cents'], 2500);
      expect(json['currency'], 'CAD');
      expect(json['merchant_name'], 'Boutique ABC');
      expect(json['merchant_reference'], 'boutique-abc');
      expect(json['customer_reference'], 'user-4521');
      expect((json['customer'] as Map)['email'], 'jean@ex.com');
      expect(json['return_url'], 'https://iziflow.ca/r');
      expect(json['cancel_url'], 'https://iziflow.ca/c');
      expect((json['metadata'] as Map)['order_id'], '123');
    });

    test('toJson omet les champs nuls', () {
      const request = IziflowSessionRequest(
        reference: 'ORD-1',
        amountCents: 100,
        merchantName: 'M',
      );

      final json = request.toJson('https://iziflow.ca/r', null);

      expect(json.containsKey('merchant_reference'), isFalse);
      expect(json.containsKey('customer_reference'), isFalse);
      expect(json.containsKey('customer'), isFalse);
      expect(json.containsKey('cancel_url'), isFalse);
      expect(json.containsKey('metadata'), isFalse);
    });
  });

  group('IziflowSession', () {
    test('fromJson parse data.payment_url', () {
      final session = IziflowSession.fromJson({
        'success': true,
        'data': {
          'reference': 'IZF-1',
          'status': 'open',
          'payment_url': 'https://checkout.iziflow.ca/checkout/abc123',
          'expires_at': '2026-10-31T15:00:00+00:00',
        },
      });

      expect(session.reference, 'IZF-1');
      expect(
        session.paymentUrl.toString(),
        'https://checkout.iziflow.ca/checkout/abc123',
      );
      expect(session.expiresAt, isNotNull);
    });

    test('fromJson sans payment_url → FormatException', () {
      expect(
        () => IziflowSession.fromJson({'success': true, 'data': {}}),
        throwsFormatException,
      );
    });
  });
}
