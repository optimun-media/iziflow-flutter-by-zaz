## 0.1.0

- Checkout par carte embarqué en WebView — le client ne quitte jamais l'app.
- Création de session via `POST /api/v1/checkout-sessions` (clé `X-Admin-Api-Key`).
- Interception des `return_url`/`cancel_url` → `IziflowPaymentResult` typé.
- Callbacks `onSuccess` / `onDeclined` / `onCancelled` / `onError` pour
  rediriger vers les pages de l'intégrateur.
- Support du coffre de cartes via `merchantReference` + `customerReference`.
- Exemple complet dans `example/`.
