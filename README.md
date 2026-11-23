# Business Central – Shopify Integration

Custom AL integration between Microsoft Dynamics 365 Business Central On-Prem and Shopify, developed from the practical implementation of the master's thesis **Integracija poslovne aplikacije i ERP sustava**.

## Current version

Version **1.6.1.0** targets Business Central 27 with AL runtime 16.1 (BC 27.1 or later). The thesis and presentation describe the earlier demonstrator, whose main result was a validated Business Central Sales Order. The current repository additionally implements sales posting, payments, payouts, refunds, fulfillment/tracking, and customer/location mapping. These additions require their own verification; the thesis screenshots are not evidence of their testing.

## Functionality

- Products, prices and physical inventory: Business Central → Shopify Admin GraphQL API.
- Paid order import, totals validation, order/line mapping, durable import registry, buffer and retry.
- Sales shipment, invoice, or shipment and invoice posting, with exact document links captured from standard BC posting events. Posting through the normal Sales Order page also updates the integration registry. Preview does not update it.
- Explicit processing of unposted imported orders even when automatic posting is off. Enabling automation also picks up previously imported, unposted orders.
- Customer payments applied to a fully posted invoice through a configured clearing G/L account.
- Shopify Payments payout import, paid deposit posting to a bank account, and fee accounting.
- Refund import, component/transaction validation, sales credit memo and customer refund. Exact inventory cost reversal follows the original invoice's Value Entries, including Ship and Invoice posting. Multiple source item entries are split into separate return lines.
- Active location mappings resolve Shopify restock locations to BC return locations; an unmapped location requires manual review.
- Fulfillment per posted BC shipment, using explicit Shopify fulfillment line IDs and quantities. Multiple partial shipments are processed individually; retries retain their original shipment reference. An incomplete quantity match sends no fulfillment mutation.
- Job Queue automation, diagnostics, configuration validation, operational status and audit snapshots. Per-record errors are preserved while processing subsequent records. Background summaries expose unresolved errors; unattended runs report failure to Job Queue after persisting their results.

## Navigation and configuration

Open **Shopify Administration Center** using Tell Me. Actions are grouped under **Setup & Health**, **Master Data**, **Orders & Posting**, **Finance**, **Fulfillment**, and **Automation & Monitoring**.

1. Configure the Shopify shop domain, API version, Client ID and Client Secret. Allow outbound HttpClient requests for the extension.
2. Configure the customer strategy, shipping item, product mappings, and either the legacy single location or active location mappings.
3. Set import cutoffs deliberately. Configure posting mode/date and the automation options to use.
4. Before recording payments/refunds, configure and validate the clearing G/L account and payment journal template/batch. Payouts additionally require the bank account, fee G/L account and payout journal context.
5. Run local validation and connection diagnostics, then verify the complete process in an isolated BC company and development Shopify store before enabling Job Queue.

**Import and Post Shopify Orders** and **Process Pending Postings** are explicit requests to process imported orders; they do not require the automatic posting option. Orders in Error require an explicit retry after their cause is corrected. Previously posted orders are not automatically posted again.

## Supported boundaries

- An imported order is routed to one BC location. Split-location orders require line-level import routing and are rejected.
- Automatic settlement currently expects one full invoice per Shopify order. Split invoices and partial payments require manual settlement; total validation prevents silently settling an incorrect amount.
- Automatic refunds support returned/restocked item lines and shipping. Unsupported restock types, adjustments, duties and other unmatched components require manual review. Item tracking and special warehouse flows need scenario-specific verification.
- Shopify refund/payout amounts must reconcile before posting. Automatic payout posting supports paid deposits, not withdrawals.
- Inventory synchronization transfers physical `on_hand`; Shopify derives `available` using its commitments. Verify inventory behavior whenever BC shipment and Shopify fulfillment are delayed or run independently.
- Shopify and BC do not share a transaction. After a remote timeout, verify Shopify before retrying fulfillment to avoid creating a duplicate remote action. Closed/insufficient remote quantities are not treated as proof that a particular local shipment succeeded.
- The order importer retains the demonstrator's 250-item/50-shipping-line limits. Fulfillment order/line reads paginate; very large order/refund imports need further pagination.
- There is no automatic historical repair of postings completed before the posting-event subscriber was installed. Check and reconcile those registry links before enabling financial automation.

## Build and verification

Build the root AL project with the AL compiler and BC 27.1 symbols. No credentials or BC service are required to compile.

A separate test app is in [`tests`](tests). Build and publish the main app first, then compile the test project against it. Tests are guarded by `SHOPIFY_TESTS`, which is defined only in the test project's manifest, so test objects are excluded from the production app. Run codeunit **50321 Shopify Test Runner** in a sandbox; it uses function isolation. GraphQL tests use a bound mock subscriber and never call a live shop.

See [verification scenarios](docs/VERIFICATION.md) for regression cases and the required live financial checks. Compilation does not execute those checks.

## Security

Client Secret values are stored in encrypted Isolated Storage; HTTP authentication uses SecretText. Credentials and access tokens are not included in this repository. Use the `BC SHOPIFY INT` permission set together with the standard BC permissions appropriate to the user's accounting and inventory work. The extension grants do not replace those standard permissions.

## Author and academic context

Nimaj Dupanović — University of Zagreb, Faculty of Organization and Informatics, 2026.
