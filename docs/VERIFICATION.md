# Verification of version 1.6.1.0

Use an isolated BC company and development Shopify shop. Financial tests create real posted documents and ledger entries in that test company. Record document numbers, amounts and resulting statuses for each scenario.

## Automated AL regression app

Compile and publish the root app, compile/publish `tests/app.json` with its `SHOPIFY_TESTS` symbol, then run codeunit 50321 **Shopify Test Runner**. It uses `TestIsolation = Function`, including rollback of explicit commits made by the code under test. Do not run the test codeunit directly without an isolating test runner.

The six regression tests cover:

1. A BC shipment of 2 out of 5 ordered items sends explicit Shopify fulfillment line quantity 2. The mock uses an IN_PROGRESS fulfillment order. A stale latest-shipment pointer in the registry must not replace the shipment stored in the fulfillment entry.
2. A shipment of 2 with only 1 remotely fulfillable unit raises an error before any fulfillment mutation.
3. Explicit processing queues an imported, unposted order while automatic posting is disabled.
4. A return location resolves through its active mapping even when the legacy default points elsewhere; an unknown location fails resolution.
5. Invalid payout setup produces an Error on each payout and continues to the next record.
6. Posting mode None produces an Error on each order and continues to the next record.

GraphQL is mocked via the `Shopify Client.OnBeforeExecuteGraphQL` event. Unexpected requests fail the test.

## Live BC and Shopify checks

| Scenario | Expected evidence |
| --- | --- |
| Full Ship and Invoice | Registry links the newly created shipment and invoice; quantities and invoice total match the imported order. |
| Standard BC posting | Open the imported order through Open BC Sales Order and use BC's normal Post action. The same registry links and Success status must be written. |
| Preview | Preview posting; registry links, status and posted documents remain unchanged. |
| Partial shipments | Import 5 units, post 2, then 3. Process fulfillment after both postings. Two entries reference their own BC shipments; Shopify receives 2 and 3, with no over-fulfillment. |
| Multiple open fulfillment orders | Split a Shopify line between fulfillment orders at the same location. Only the quantities matching the local shipment are sent, across the necessary orders. |
| Failed second posting | After one partial shipment, cause the next posting to fail. The old shipment must not make the attempt successful; the actual BC error is recorded. |
| Manual processing, automation off | Import with automatic posting off; explicitly run Import and Post. The order is queued and posted using the configured mode. |
| Enable automation later | Import with automatic posting off, then enable it. A subsequent background run picks up the previously unposted order. |
| Payment | Post a full invoice and record payment. Verify customer balance closes, payment document/ledger links are saved, and clearing account is debited once. Repeating must not create a second payment. |
| Payout failure isolation | Put an invalid-currency paid deposit before a valid paid deposit. The first stores Error, the second posts; the background summary and Job Queue expose the error. |
| Full/partial refund after Ship and Invoice | Refund a supported returned/restocked line. The credit memo reverses the original item's cost via invoice Value Entries even if invoice shipment fields are blank; customer refund closes the credit memo and credits clearing. |
| Multiple item ledger entries | Sell an item split across original outbound entries, then return quantities covering both. Separate credit memo lines apply to the corresponding entries; quantities/costs reconcile. |
| Refund to another mapped location | Return to an active mapped Shopify location different from the legacy default. Verify the BC receipt goes to that mapped return location. An unmapped location must require Manual Review. |
| Refund posting failure | Cause customer refund posting to fail after credit memo creation would have started. No partial credit memo/ledger posting should remain from that attempt; retry after correction must post once. |
| Background summary | Force one record to fail while others succeed. The final summary must report errors, the failed record must persist its cause, and the unattended Job Queue run must not report success. |
| Remote timeout | If Shopify may have accepted a fulfillment before its response was lost, inspect the remote order before retrying. Do not infer a successful shipment from unrelated closed fulfillment orders. |

## Build evidence

The production and test projects can be compiled with Microsoft's AL compiler and BC 27.1 symbol packages from the public MSSymbols NuGet feed. Runtime tests require a BC service; a successful compile is not a runtime or accounting verification.
