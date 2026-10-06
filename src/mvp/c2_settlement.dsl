// c2_settlement.dsl — Settlement Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'settlement'.

// ---------- People (MVP demo roles) ----------
financeViewer = person "Finance Viewer (Demo: Manager)" "Views balances, holds, and entry history for each member credit union."

// ---------- Test tools ----------
simulator = softwareSystem "Payment Simulator" "Test tool that plays the role of the Clearing Platform. Sends reserve, post, and release requests, including duplicates and simultaneous ones." "Test Tool"

// ---------- Relationships ----------
// 'developer' is declared in c2_clearing.dsl (included before this file)
// 'identity' is declared in c1.dsl
financeViewer -> ledgerService "Views balances and entry history using" "HTTPS"
developer -> simulator "Runs load and duplicate-request tests with" "Command line"
developer -> integrityJob "Triggers on demand and reviews results of" "Command line"

simulator -> ledgerService "Reserves funds, posts entries, releases holds, and queries balances with" "HTTPS/JSON"
ledgerService -> identity "Validates tokens with" "OpenID Connect"
ledgerService -> ledgerDb "Reads and writes entries, balances, holds, and idempotency keys" "SQL"

integrityJob -> ledgerDb "Reads entries and balances, and stores check results in" "SQL"

eventPublisher -> ledgerDb "Reads new outbox events from" "SQL"
eventPublisher -> simulator "Sends balance-changed events to" "Webhooks/HTTPS"

// ---------- Downstream consumers ----------
postSettlement -> ledgerService "Reads entries and balances from" "HTTPS/JSON, OAuth2 client credentials"
postSettlement -> ledgerService "Sends approved correcting entries to" "HTTPS/JSON, OAuth2 client credentials"
