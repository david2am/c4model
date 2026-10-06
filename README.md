# OnePlatform C4 Model

Architecture diagrams for the OnePlatform payment processing pipeline — covering clearing, settlement, and post-settlement — using the [C4 model](https://c4model.com/) and [Structurizr DSL](https://docs.structurizr.com/dsl).

## Diagrams

| Diagram | View type | What it shows |
|---|---|---|
| System Landscape | Landscape | All three platforms, every external system, and every person — side by side |
| System Context — Full Pipeline | C1 | Everyone and everything involved in the pipeline, from credit union member to accounting |
| System Context — Settlement | C1 | The Settlement Platform and every system that directly interacts with it |
| Clearing Platform | C2 | Containers of the Clearing Platform and their neighbours |
| Settlement Platform | C2 | Containers of the Settlement Platform and their neighbours |
| Post-Settlement Platform | C2 | Containers of the Post-Settlement Platform (future) and their neighbours |
| Happy Path | Dynamic | Outbound FedNow payment from credit union core to network confirmation and core notification |
| Reserve and Post | Dynamic | How funds are held then posted in the Settlement Platform for one payment |
| End to End (Inbound) | Dynamic | Inbound FedNow credit received from the network and credited to a member's account |
| Worker Crash | Dynamic | Payment Worker crash and recovery — lease expiry, idempotent retry, and dead-letter |
| Daily Reconciliation | Dynamic | Post-Settlement cut-off, data collection, and cross-system reconciliation |
| Correction Approval | Dynamic | Two-person correction flow: proposal → approval → ledger post with approver identity |

## System overview

The three platforms cover the full lifecycle of a payment:

- **Clearing Platform** — receives outbound payment requests from credit union cores, screens them against OFAC (blocks if unavailable — never silently bypassed), reserves settlement funds, routes ISO 20022 messages to FedNow or RTP, tracks network answers, posts final entries, and notifies credit union cores. Also handles inbound credits arriving from the networks and return messages (pacs.004, R-transactions). Unrecoverable work items go to a dead-letter table for operations staff.
- **Settlement Platform** — real-time record of member credit union balances. Handles holds, posts, and releases; rejects overdrafts; enforces per-credit-union data isolation; accepts correcting entries (idempotent, with approver identity in the payload); manages the business day boundary via the Business Day Scheduler; and serves entries and balances as of the cut-off time. The Integrity Check Job continuously verifies that debits equal credits and that no holds are stuck.
- **Post-Settlement Platform** *(future)* — runs after the settlement cut-off to reconcile numbers across systems, manage exceptions and corrections, produce member statements and regulatory reports, and feed the Corporate General Ledger. The Data Collector downloads Fed statements via FedLine API (HTTPS) and RTP reports via SFTP from TCH — two different protocols. The Accounting Exporter carries a batch ID per day so the GL never receives the same day twice and retries on GL unavailability.

**Key distinctions:**
- **Settlement Platform** is the real-time record of member credit union positions. **Corporate General Ledger** is OnePlatform's own accounting record for financial statements. They serve different purposes and are kept separate.
- **FedNow** and **RTP** have different settlement models: FedNow movements debit/credit OnePlatform's master account at the Federal Reserve; RTP movements adjust OnePlatform's prefunded position account held at TCH.
- **Corrections** require two different people (two-person rule): one proposes, a different one approves. The approver's identity is embedded in the payload sent to the Ledger Service.

## File structure

```
src/c1.dsl                        # System-level model: all people, software systems, container
                                  # declarations, and system-level relationships (outbound, inbound,
                                  # returns, monitoring, auth, post-settlement)
src/mvp/c2_clearing.dsl           # Clearing Platform: MVP test tools, container relationships
src/mvp/c2_settlement.dsl         # Settlement Platform: MVP test tools, container relationships
src/mvp/c2_post-settlement.dsl    # Post-Settlement Platform: people and container relationships
workspace.dsl                     # Composes all fragments; declares all views and styles
src/complete/                     # Archived standalone workspace files (not active)
```

`c1.dsl` is the single source of truth for all `softwareSystem` and `container` declarations. The `c2_*.dsl` files are relationship fragments — they declare fragment-specific people, test tools, and relationships, but never redefine systems or containers.

## Running locally

Requires Docker.

```bash
docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
```

Then open [http://localhost:8080](http://localhost:8080). The diagrams appear in the left panel.

## Conventions

- **`c1.dsl`** — declares all people, software systems, container definitions, and system-level relationships. Containers are co-located with their `softwareSystem` so identifiers are available to every included fragment.
- **`c2_*.dsl`** — relationship fragments only. Each adds fragment-specific people, test tools, and relationships between containers. No `workspace {}` wrapper.
- **`workspace.dsl`** — the entry point. Includes fragments in order (`c1` → `c2_clearing` → `c2_settlement` → `c2_post-settlement`) and declares all views.
- **Clearing and Settlement diagrams** show the MVP: simulators stand in for real external systems (FedNow, credit union cores, the screening service). The Post-Settlement diagram shows the real systems it will integrate with.
- **Post-Settlement containers** carry a `Future` tag and render with a dashed border to signal they are not yet built.
- **Event Publisher and Settlement Event Bus** carry a `Stretch` tag — for the MVP the Data Collector polls the Ledger Service directly.
- **Service-to-service calls** (Clearing → Settlement, Post-Settlement → both) use OAuth2 client credentials, noted in relationship technology labels.
- **Network protocols** are explicit: FedNow uses ISO 20022 over mTLS (Fed-issued certificates required); RTP uses ISO 20022 over mTLS with TCH. FedNow statements come via FedLine API (HTTPS); RTP reports come via SFTP from TCH.
- **Dead-letter handling** — unrecoverable payment work items are moved to a dead-letter table in the Platform Database for manual review by operations staff.
- **Business day boundary** — the Business Day Scheduler marks the cut-off time in the Ledger Database. Entries after cut-off belong to the next business day. This drives the downstream collector and reconciliation sequencing.

## Open questions

These items are not yet modelled. Decisions needed before building:

1. **Correction notifications** — when Post-Settlement sends a correcting entry that changes a balance, does the affected credit union's core (`cuCore`) need to be notified in real time?
2. **Return / retry via Clearing** — if a reconciliation break is caused by a bad payment, can Post-Settlement ask the Clearing Platform to initiate a formal network return (pacs.004)?
3. **Liquidity monitor** — the `complete/c2_payment.dsl` archive has a `liquidityMonitor` container that watches positions against thresholds and raises alerts. This has not been ported to the MVP. Is it in scope for MVP or a stretch goal?
4. **Read replica for ledger** — the `complete/c2_settlement.dsl` archive has a read replica for balance queries. At what transaction volume does the single `ledgerDb` become a bottleneck? Flag this for capacity planning before go-live.
5. **System landscape view** — added. See `SystemLandscape-001`.
