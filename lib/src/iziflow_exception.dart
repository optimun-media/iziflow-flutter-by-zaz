/// Erreur levée quand l'API IziFlow répond mal ou est injoignable.
class IziflowException implements Exception {
  const IziflowException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'IziflowException(${statusCode ?? 'network'}): $message';
}
