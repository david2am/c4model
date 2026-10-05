# OnePlatform C4 Model

Architecture diagrams for the OnePlatform payment processing pipeline — covering clearing, settlement, and post-settlement — using the [C4 model](https://c4model.com/) and [Structurizr DSL](https://docs.structurizr.com/dsl).

## Diagrams

Four diagrams are published in the workspace:

| Diagram | View type | What it shows |
|---|---|---|
| System Context | C1 | All people and systems that interact with the Clearing Platform |
| Clearing Platform | C2 | Internal containers of the Clearing Platform |
| Settlement Platform | C2 | Internal containers of the Settlement Platform |
| Post-Settlement Platform | C2 | Internal containers of the Post-Settlement Platform |

## File structure

```
c1.dsl                   # System-level model: people, software systems, and all system-level relationships
c2_payment.dsl           # Clearing Platform: demo people, test tools, and container relationships
c2_settlement.dsl        # Settlement Platform: demo people, test tools, and container relationships
c2_post-settlement.dsl   # Post-Settlement Platform: people and container relationships
workspace.dsl            # Composes all fragments and declares the four views
general/                 # Archived complete-system C2 files, not active
```

`c1.dsl` is the single source of truth for all softwareSystem and container declarations. The `c2_*.dsl` files are relationship fragments — they declare fragment-specific people and relationships but never redefine systems or containers.

## System overview

The three platforms cover the full lifecycle of a payment:

- **Clearing Platform** — receives payment requests from credit unions, screens them, routes them to payment networks (FedNow, RTP), and tracks results.
- **Settlement Platform** — maintains the ledger of member credit union accounts: balances, holds, and a full entry history with duplicate-safe fund reservation and posting.
- **Post-Settlement Platform** *(future)* — runs after settlement to reconcile numbers, manage exceptions, produce member statements and regulatory reports, and feed the corporate general ledger.

## Running locally

Requires Docker.

```bash
docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
```

Then open [http://localhost:8080](http://localhost:8080) in your browser. The four diagrams appear in the left panel.

## Conventions

- **`c1.dsl`** — declares all people, software systems, container definitions, and system-level relationships. Containers are co-located with their softwareSystem here so identifiers are available to every included fragment.
- **`c2_*.dsl`** — relationship fragments only. Each file adds fragment-specific people, test tools, and relationships between containers. No `workspace {}` wrapper.
- **`workspace.dsl`** — the entry point. Includes fragments in order (`c1` → `c2_payment` → `c2_settlement` → `c2_post-settlement`) and declares exactly one view per diagram.
- The `general/` folder holds archived standalone workspace files and is not included in the active workspace.
