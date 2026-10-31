/// Coordonnées du client final — utilisées pour pré-remplir le
/// formulaire de paiement hébergé.
class IziflowCustomer {
  const IziflowCustomer({this.name, this.email, this.phone});

  final String? name;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
  };
}
