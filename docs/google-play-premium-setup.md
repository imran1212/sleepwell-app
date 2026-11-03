# SleepWell Premium — Google Play Console setup

The Flutter app queries these exact product IDs:

| Product ID | Google Play product type | Billing behavior |
|---|---|---|
| `sleepwell_premium_monthly` | Subscription | Monthly auto-renewing base plan |
| `sleepwell_premium_yearly` | Subscription | Yearly auto-renewing base plan |
| `sleepwell_premium_lifetime` | One-time product (non-consumable) | One-time permanent purchase |

## Play Console checklist

1. Create the app in Play Console and complete the required app setup.
2. Open **Monetize with Play > Products > Subscriptions**.
3. Create `sleepwell_premium_monthly` and add an active monthly auto-renewing base plan.
4. Create `sleepwell_premium_yearly` and add an active yearly auto-renewing base plan.
5. Open **Monetize with Play > Products > One-time products** and create `sleepwell_premium_lifetime` as a one-time product.
6. Set regional prices, activate all products/base plans, and save.
7. Upload a signed release build to an internal testing track. Add tester Google accounts and install the app from the Play Store testing link to test billing.

## Important release requirements

- Product IDs are case-sensitive and must match exactly.
- Prices are fetched from Google Play; no hard-coded prices are in the app.
- Test purchases require an app build distributed through a Play testing track and tester accounts configured in Play Console.
- The current GitHub Actions workflow produces a **debug APK**, which is for device testing and is not a Play Store release artifact.
- A Play upload needs a signed release APK or, preferably, a signed Android App Bundle (AAB) using the app's registered upload key.
- Before production launch, implement server-side purchase-token verification and subscription entitlement checks. The current client purchase listener is an initial integration and is not sufficient as a secure production entitlement system.
- Premium-gated features currently include the ambient sound library and custom routine steps. Breathing timer and standard routine remain available without payment.
