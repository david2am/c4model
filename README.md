# OneCredit C4 Model

Architecture diagrams for the OneCredit Clearing Platform and Settlement Accounts, using the [C4 model](https://c4model.com/) and [Structurizr DSL](https://docs.structurizr.com/dsl).

## Diagrams

Three diagrams are published in the workspace:

| Diagram | View type | What it shows |
|---|---|---|
| System Context | C1 | People and systems that interact with the Clearing Platform |
| Clearing MVP — Containers | C2 | Internal containers of the Clearing Platform |
| Settlement Accounts MVP — Containers | C2 | Internal containers of the Settlement Platform ledger |

## File structure

```
c1.dsl                   # System-level model: people, software systems, relationships
c2_payment_mvp.dsl       # Payment platform MVP: demo people, test tools, container relationships
c2_settlement_mvp.dsl    # Settlement ledger MVP: demo people, test tools, container relationships
workspace.dsl            # Composes the three fragments and declares the views
general/                 # Complete (non-MVP) versions of the C2 diagrams, not active
```

`c1.dsl` is the source of truth for all softwareSystem and container declarations. The `c2_*.dsl` files are fragments — they declare demo-specific people, test tools, and relationships, but do not redefine systems or containers.

## Running locally

Requires Docker.

```bash
docker run -p 8080:8080 -v $(pwd):/usr/local/structurizr structurizr/lite
```

Then open [http://localhost:8080](http://localhost:8080) in your browser. The three diagrams appear in the left panel.

## Conventions

- **`c1.dsl`** — C1 level only: people, software systems, and system-level relationships. Container declarations live here too so identifiers are available to the included fragments.
- **`c2_*_mvp.dsl`** — C2 level fragments: add demo people, test-tool systems, and relationships between containers. No `workspace {}` wrapper.
- **`workspace.dsl`** — the entry point. Includes the fragments in order (`c1` → `c2_payment_mvp` → `c2_settlement_mvp`) and declares exactly one view per diagram.
- The `general/` folder holds the complete-system C2 files. They are standalone workspaces and are not included in the MVP workspace.
