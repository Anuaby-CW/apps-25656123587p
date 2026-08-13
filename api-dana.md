
# DANA Merchant Portal API Documentation

> Curated LLM entry point for DANA Merchant Portal API documentation. Use these Markdown files to understand onboarding, authentication, sandbox testing, Gapura Payment Gateway integration, API behavior, and settlement reporting.

## Start Here

- [DANA Enterprise Overview](https://dashboard.dana.id/api-docs-v2/llms/guide/overview.md): High-level overview of DANA Enterprise solutions, including Gapura Payment Gateway, Integrated Payment, Disbursement, and Submerchants.
- [Getting Started](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/getting-started-onboarding.md): Steps to create a DANA Enterprise account, complete business information, and access the onboarding dashboard.
- [Business Verification Overview](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/business-verification-overview.md): Business document verification, required documents, upload flow, and validation steps.
- [Integration Overview](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/integration-overview.md): Developer dashboard, webhook setup, credentials, and integration preparation.

## Developer Tools

- [Authentication Asymmetric SNAP](https://dashboard.dana.id/api-docs-v2/llms/guide/authentication/authentication-asymmetric.md): Asymmetric signature authentication, public/private key usage, credential setup, and SNAP request signing.
- [Libraries](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/libraries.md): DANA API client libraries and self-testing tools for Go, Node.js, Java, PHP, and Python.
- [Sandbox Tools](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/sandbox-tools.md): Sandbox helper tools for transaction simulation and integration testing.
- [Scenario Testing](https://dashboard.dana.id/api-docs-v2/llms/guide/scenario-testing.md): UAT scenario checklist and testing flow before going live.

## Recommended Integration Paths

Use [DANA libraries](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/libraries.md) to integrate faster and reduce manual work for request signing, request formatting, and response parsing.

| Goal | Use This When | Primary Docs | API References |
| --- | --- | --- | --- |
| Custom Checkout with SDK | Merchant builds their own checkout page, consults available payment methods, and creates orders through DANA APIs. | [Libraries](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/libraries.md), [Authentication Asymmetric SNAP](https://dashboard.dana.id/api-docs-v2/llms/guide/authentication/authentication-asymmetric.md), [Gapura Custom Checkout Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/payment-gateway/custom-checkout.md) | [Consult Pay](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/consult-pay.md), [Create Order - Custom Checkout](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/create-order-custom.md), [Finish Notify](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/finish-notify.md) |
| Hosted Checkout with SDK | Merchant redirects users to a DANA-hosted checkout page and receives payment notification after completion. | [Libraries](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/libraries.md), [Authentication Asymmetric SNAP](https://dashboard.dana.id/api-docs-v2/llms/guide/authentication/authentication-asymmetric.md), [Gapura Hosted Checkout Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/payment-gateway/hosted-checkout.md) | [Create Order - Hosted Checkout](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/create-order-hosted.md), [Finish Notify](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/finish-notify.md) |
| DANA Widget Binding with SDK | Merchant links a user's DANA account to the merchant platform, exchanges authCode for accessToken, then creates DANA Widget payments. | [Libraries](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/libraries.md), [Authentication Asymmetric SNAP](https://dashboard.dana.id/api-docs-v2/llms/guide/authentication/authentication-asymmetric.md), [DANA Widget Binding Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/widget-binding.md), [Deeplink Binding and Payment](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/deeplink-binding-and-payment.md) | [Deeplink Binding](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/deeplink-binding.md), [Apply Token](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/apply-token.md), [Apply OTT](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/apply-ott.md), [Direct Debit Payment](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/direct-debit-payment.md), [Finish Notify](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/finish-notify.md) |
| DANA Widget Non Binding with SDK | Merchant lets users pay with DANA without account binding, redirecting users to DANA App or Web View to complete payment. | [Libraries](https://dashboard.dana.id/api-docs-v2/llms/guide/getting-started/libraries.md), [Authentication Asymmetric SNAP](https://dashboard.dana.id/api-docs-v2/llms/guide/authentication/authentication-asymmetric.md), [DANA Widget Non Binding Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/widget-non-binding.md), [Deeplink Binding and Payment](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/deeplink-binding-and-payment.md) | [Direct Debit Payment](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/direct-debit-payment.md), [Finish Notify](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/finish-notify.md) |
| DANA Widget post-payment operations | Merchant needs to check DANA Widget payment status, cancel an order, or refund a DANA Widget payment after order creation. | [DANA Widget API Overview](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/overview.md) | [Query Payment](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/query-payment.md), [Cancel Order](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/cancel-order.md), [Refund Order](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/refund-order.md) |
| DANA Widget account and transaction inquiry | Merchant needs to unbind a user's DANA account, query user profile data, check balance, or retrieve DANA transaction history and details. | [DANA Widget API Overview](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/overview.md), [DANA Widget Binding Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/widget-binding.md) | [Account Unbinding](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/account-unbinding.md), [Query User Profile](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/query-user-profile.md), [Balance Inquiry](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/balance-inquiry.md), [Transaction History](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/transaction-history.md), [Transaction Detail](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/transaction-detail.md), [Unbind Notify](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/unbind-notify.md) |

## API Basics

- [API Overview](https://dashboard.dana.id/api-docs-v2/llms/api/overview.md): REST API behavior, base URLs, sandbox and production endpoints, and general API conventions.
- [API Status](https://dashboard.dana.id/api-docs-v2/llms/api/api-status.md): DANA Sandbox API status monitoring, uptime, maintenance windows, and live status page.

## Gapura Payment Gateway Overview

- [Gapura Payment Gateway Overview](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/overview.md): Gapura solution overview, Hosted Checkout and Custom Checkout scenarios, process flows, required APIs, optional APIs, and settlement reference.

## Gapura Solution Guides

- [Gapura Custom Checkout Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/payment-gateway/custom-checkout.md): Integration guide for merchants that build their own checkout page and use DANA payment APIs directly.
- [Gapura Hosted Checkout Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/payment-gateway/hosted-checkout.md): Integration guide for merchants that redirect users to a DANA-hosted checkout page.

## Gapura Payment Gateway APIs

- [Consult Pay](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/consult-pay.md): Consult available payment methods or payment channels before creating an order for Custom Checkout.
- [Create Order - Custom Checkout](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/create-order-custom.md): Create a Payment Gateway order for Custom Checkout flows, including idempotency, pay options, URL params, and additional info.
- [Create Order - Hosted Checkout](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/create-order-hosted.md): Create a Payment Gateway order for Hosted Checkout flows and receive a checkout redirect URL.
- [Finish Notify](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/finish-notify.md): Webhook notification from DANA to merchant systems for payment status and transaction information.

## Gapura Optional APIs

- [Query Payment](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/optional-api/query-payment.md): Query payment status and transaction details from merchant systems to DANA.
- [Cancel Order](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/optional-api/cancel-order.md): Cancel an existing Payment Gateway order from the merchant platform.
- [Refund Order](https://dashboard.dana.id/api-docs-v2/llms/api/payment-gateway/optional-api/refund-order.md): Refund a Payment Gateway order, including refund amount, partner refund number, and refund response handling.

## DANA Widget Overview

- [DANA Widget API Overview](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/overview.md): DANA Widget Binding and Non Binding solution overview, API lists, deeplink behavior, process flows, optional APIs, and settlement reference.

## DANA Widget Solution Guides

- [DANA Widget Binding Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/widget-binding.md): Integration guide for binding a user's DANA account to a merchant platform and using bound-account payment flows.
- [DANA Widget Non Binding Guide](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/widget-non-binding.md): Integration guide for DANA payments without account binding.
- [Deeplink Binding and Payment](https://dashboard.dana.id/api-docs-v2/llms/guide/dana-widget/deeplink-binding-and-payment.md): Deeplink and universal-link guidance for redirecting users to the DANA App for binding and payment.

## DANA Widget Mandatory APIs

- [Deeplink Binding](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/deeplink-binding.md): Generate a binding URL to redirect users to the DANA App and initiate account binding.
- [Apply Token](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/apply-token.md): Exchange authCode for accessToken and refreshToken after successful binding.
- [Apply OTT](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/apply-ott.md): Convert a user's accessToken into a one-time token for DANA Widget checkout redirection.
- [Direct Debit Payment](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/direct-debit-payment.md): Initiate DANA Widget payment and receive checkout redirect information.
- [Finish Notify](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/finish-notify.md): Webhook notification from DANA to merchant systems for DANA Widget payment status and transaction information.

## DANA Widget Optional APIs

- [Account Unbinding](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/account-unbinding.md): Revoke accessToken and refreshToken to remove a user's bound DANA account.
- [Query Payment](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/query-payment.md): Query DANA Widget payment status and transaction details.
- [Cancel Order](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/cancel-order.md): Cancel a DANA Widget order from the merchant platform.
- [Refund Order](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/refund-order.md): Refund a completed DANA Widget order.
- [Balance Inquiry](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/balance-inquiry.md): Query a user's DANA account balance through the merchant platform.
- [Transaction History](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/transaction-history.md): Query a user's DANA transaction history list through the merchant platform.
- [Transaction Detail](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/transaction-detail.md): Query detailed information for a DANA transaction.
- [Query User Profile](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/query-user-profile.md): Obtain user profile information such as masked phone number, KYC status, DANA balance, or OTT.
- [Unbind Notify](https://dashboard.dana.id/api-docs-v2/llms/api/dana-widget/optional-api/unbind-notify.md): Receive notification when a user unbinds a DANA account from the DANA App.

## Settlement

- [Payment Services Settlement File](https://dashboard.dana.id/api-docs-v2/llms/guide/settlement-file/payment-services.md): Settlement file specification, file generation, download flow, and field-level settlement report details for payment services.
