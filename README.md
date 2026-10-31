# iziflow_flutter

Plugin Flutter officiel du checkout **IziFlow** — paiement par carte (et bientôt mobile money) intégré directement dans votre application, **sans jamais ouvrir de navigateur externe**.

> Créé par **Achaire ZOGO**.

## Pourquoi ce plugin ?

- **Checkout embarqué** : la page de paiement hébergée IziFlow s'affiche dans un WebView plein écran de votre app. L'utilisateur ne quitte jamais votre application — saisie de carte, authentification 3-D Secure chez sa banque et reçu se déroulent à l'intérieur.
- **Aucune donnée de carte dans votre app** : le PAN est collecté exclusivement par la page hébergée IziFlow. Votre application ne voit jamais le numéro de carte — un avantage PCI décisif.
- **Redirections vers vos pages** : à la fin du paiement, des callbacks vous indiquent le résultat (`success` / `declined` / `cancelled` / `error`) pour que vous naviguiez vers vos propres écrans (succès, échec, retour panier).
- **Coffre de cartes** : en passant `merchantReference` + `customerReference`, les cartes enregistrées du client lui sont proposées et il peut mémoriser sa carte pour ses prochains paiements.

## Installation

```yaml
dependencies:
  iziflow_flutter:
    git:
      url: https://github.com/optimun-media/iziflow-flutter-by-zaz.git
      ref: main
```

## Prérequis

1. Une **clé API IziFlow** (envoyée en header `X-Admin-Api-Key`).
2. Les domaines de `returnUrl`/`cancelUrl` doivent être autorisés côté serveur (`MONERIS_ALLOWED_RETURN_HOSTS`). Les valeurs par défaut pointent vers `iziflow.ca` — déjà whitelisté — et ne sont jamais ouvertes : elles servent uniquement de signal de fin de paiement intercepté par le SDK.

## Utilisation

```dart
import 'package:iziflow_flutter/iziflow_flutter.dart';

final result = await IziflowCheckout.pay(
  context,
  config: const IziflowConfig(apiKey: 'votre-cle-api'),
  request: IziflowSessionRequest(
    reference: 'ORDER-123',        // référence unique de la commande (idempotence)
    amountCents: 2500,             // 25,00 $ — minimum 50
    currency: 'CAD',               // CAD ou USD
    merchantName: 'Boutique ABC',  // affiché « Paiement à Boutique ABC »
    merchantReference: 'boutique-abc',
    customerReference: 'user-4521',
    customer: const IziflowCustomer(
      name: 'Jean Dupont',
      email: 'jean@exemple.com',
    ),
    metadata: {'order_id': 'ORDER-123'},
  ),

  // ↓ Redirigez ici vers VOS pages selon la réponse de l'API ↓
  onSuccess: (r) => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => PaymentSuccessPage(result: r))),
  onDeclined: (r) => Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => PaymentFailedPage(result: r))),
  onCancelled: (_) {},   // retour silencieux au panier
  onError: (r) => showSnackBar(context, r.message),
);

// Le même résultat est aussi renvoyé par le Future pour un traitement `await`.
if (result.isSuccess) {
  // result.receiptId  → identifiant Moneris (preuve de paiement)
  // result.reference  → votre référence
  // result.orderId    → metadata.order_id renvoyé par le serveur
}
```

## Paramètres

### `IziflowConfig`

| Paramètre | Défaut | Rôle |
|---|---|---|
| `apiKey` *(requis)* | — | Clé API interne IziFlow |
| `baseUrl` | `https://checkout.iziflow.ca` | Racine du service de paiement |
| `returnUrl` | `https://iziflow.ca/iziflow-checkout/return` | URL interceptée en fin de paiement |
| `cancelUrl` | `https://iziflow.ca/iziflow-checkout/cancel` | URL interceptée à l'annulation |
| `timeout` | 30 s | Timeout HTTP des appels API |

### `IziflowSessionRequest`

| Paramètre | Requis | Rôle |
|---|---|---|
| `reference` | ✔ | Référence unique de la commande — clé d'idempotence |
| `amountCents` | ✔ | Montant en cents (≥ 50) |
| `merchantName` | ✔ | Nom du marchand affiché sur la page de paiement |
| `currency` | | `CAD` (défaut) ou `USD` |
| `merchantReference` | | Identifiant du marchand — active le coffre de cartes |
| `customerReference` | | Identifiant du client final — cartes enregistrées + « mémoriser » |
| `customer` | | `name` / `email` / `phone` pour pré-remplir le formulaire |
| `metadata` | | Données libres — `order_id` est renvoyé dans le résultat |

### Callbacks de `IziflowCheckout.pay`

| Callback | Déclenché quand |
|---|---|
| `onSuccess` | `status=success` sur la return_url — le paiement est accepté |
| `onDeclined` | `status=failed` — la banque a refusé |
| `onCancelled` | cancel_url interceptée **ou** fermeture de la page par le client (`aborted`) |
| `onError` | API injoignable, session refusée, réponse invalide |

### `IziflowPaymentResult`

| Champ | Contenu |
|---|---|
| `status` | `success` / `declined` / `cancelled` / `aborted` / `error` |
| `reference` | Votre référence de session |
| `orderId` | `metadata.order_id` renvoyé par le serveur |
| `receiptId` | `paymentId` Moneris — présent en cas de succès |
| `message` | Détail en cas d'erreur |

## Fonctionnement interne

1. `IziflowClient` appelle `POST {baseUrl}/api/v1/checkout-sessions` avec votre clé API → récupère `payment_url`.
2. `IziflowCheckoutPage` charge cette URL dans un WebView embarqué (JavaScript activé pour le 3-D Secure, navigation HTTPS uniquement, schemes externes `tel:`/`mailto:` bloqués).
3. Quand le serveur redirige vers `return_url` ou `cancel_url`, `IziflowReturnParser` intercepte la navigation — la page n'est jamais chargée — et produit un `IziflowPaymentResult`.
4. `IziflowCheckout.pay` ferme la page, dispatche le résultat vers le bon callback, puis le renvoie aussi dans son `Future`.

## Exemple complet

Une app démo fonctionnelle est dans [`example/`](example/lib/main.dart) :

```bash
cd example && flutter run
```

## Feuille de route

- [x] Paiement par carte (checkout hébergé + 3-D Secure)
- [x] Coffre de cartes — réutilisation sans ressaisie
- [ ] Paiements mobile money (Orange Money, MTN MoMo…)
- [ ] Mode bottom-sheet en alternative à la pleine page

## Sécurité

- La clé API reste côté client applicatif — pour des intégrations sensibles, créez la session depuis votre backend et ouvrez `IziflowCheckoutPage` directement avec l'URL obtenue.
- Le WebView n'accepte que des navigations HTTPS ; toute tentative de sortir vers une app externe est bloquée.
- Aucun journal côté SDK : les données de carte ne quittent jamais la page hébergée.

## Licence

MIT — IziFlow © Achaire ZOGO.
