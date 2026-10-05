# OnePlatform C4 Model

Architecture diagrams for the OnePlatform payment processing pipeline — covering clearing, settlement, and post-settlement — using the [C4 model](https://c4model.com/) and [Structurizr DSL](https://docs.structurizr.com/dsl).

## Diagrams

| Diagram | View type | What it shows |
|---|---|---|
| System Context | C1 | All people and systems that interact with the Clearing Platform |
| Clearing Platform | C2 | Containers of the Clearing Platform and their neighbours |
| Settlement Platform | C2 | Containers of the Settlement Platform and their neighbours |
| Post-Settlement Platform | C2 | Containers of the Post-Settlement Platform (future) and their neighbours |

## System overview

The three platforms cover the full lifecycle of a payment:

- **Clearing Platform** — receives payment requests from credit unions, screens them, routes them to payment networks (FedNow, RTP), and tracks results. Exposes payment records for downstream reconciliation.
- **Settlement Platform** — maintains the ledger of member credit union accounts: balances, holds, and a full entry history. Accepts correcting entries (idempotent, with approver identity) and serves entries and balances as of a cut-off time.
- **Post-Settlement Platform** *(future)* — runs after settlement to reconcile numbers across systems, manage exceptions and corrections, produce member statements and regulatory reports, and feed the corporate general ledger. Containers are marked with a dashed border in the diagrams.

## File structure

```
c1.dsl                   # System-level model: all people, software systems, container
                         # declarations, and system-level relationships
c2_payment.dsl           # Clearing Platform: demo people, test tools, container relationships
c2_settlement.dsl        # Settlement Platform: demo people, test tools, container relationships
c2_post-settlement.dsl   # Post-Settlement Platform: people and container relationships
workspace.dsl            # Composes all fragments and declares the four views
general/                 # Archived standalone workspace files, not active
```

`c1.dsl` is the single source of truth for all softwareSystem and container declarations. The `c2_*.dsl` files are relationship fragments — they declare fragment-specific people and add relationships, but never redefine systems or containers.

## Running locally

Requires Docker.

```bash
docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
```

Then open [http://localhost:8080](http://localhost:8080). The four diagrams appear in the left panel.

## Conventions

- **`c1.dsl`** — declares all people, software systems, container definitions, and system-level relationships. Containers are co-located with their softwareSystem so identifiers are available to every included fragment.
- **`c2_*.dsl`** — relationship fragments only. Each adds fragment-specific people, test tools, and relationships between containers. No `workspace {}` wrapper.
- **`workspace.dsl`** — the entry point. Includes fragments in order (`c1` → `c2_payment` → `c2_settlement` → `c2_post-settlement`) and declares exactly one view per diagram.
- **Clearing and Settlement diagrams** show the MVP: simulators stand in for real external systems (FedNow, credit union cores, the screening service). The Post-Settlement diagram shows the real systems it will integrate with.
- **Post-Settlement containers** carry a `Future` tag and render with a dashed border to signal they are not yet built.
- **Service-to-service calls** (Clearing → Settlement, Post-Settlement → both) use OAuth2 client credentials, noted in the relationship technology labels.
- **Polling vs. events** — for the MVP, the Data Collector polls the Ledger Service directly. The Event Publisher (stretch goal) is not yet wired to the collector.

## Open questions

These items are not modelled yet. Decisions needed before Post-Settlement is built:

1. **Correction notifications** — when Post-Settlement sends a correcting entry that changes a balance, does the affected credit union's core (`cuCore`) need to be notified? If yes, a relationship from `api` or `reportGenerator` to `cuCore` should be added.
2. **Return / retry via Clearing** — if a break is caused by a bad payment, can Post-Settlement ask the Clearing Platform to initiate a return or retry? If yes, a relationship from `api` to `orchestratorApi` is needed, along with the corresponding use case.
3. **Dynamic views** — the two-person correction approval flow and the daily reconciliation sequence are good candidates for dynamic views. Not added yet.
4. **System landscape view** — a single view showing all three platforms together has not been added yet.
