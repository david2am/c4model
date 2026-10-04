// c2_settlement_mvp.dsl — Settlement Accounts MVP relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'coLedger'.

// ---------- People (MVP demo roles) ----------
financeViewer = person "Finance Viewer (Demo: Manager)" "Views balances, holds, and entry history for each member credit union."

// ---------- Test tools ----------
simulator = softwareSystem "Payment Simulator" "Test tool that plays the role of the Payment Orchestration Platform. Sends reserve, post, and release requests, including duplicates and simultaneous ones." "Test Tool"

// ---------- Relationships ----------
// 'developer' is declared in c2_payment_mvp.dsl (included before this file)
// 'identity' is declared in c1.dsl
financeViewer -> ledgerService "Views balances and entry history using" "HTTPS"
developer -> simulator "Runs load and duplicate-request tests with" "Command line"
developer -> integrityJob "Triggers on demand and reviews results of" "Command line"

simulator -> ledgerService "Reserves funds, posts entries, releases holds, and queries balances with" "HTTPS/JSON"
ledgerService -> identity "Validates sign-ins and tokens with" "OpenID Connect"
ledgerService -> ledgerDb "Reads and writes entries, balances, holds, and idempotency keys" "SQL"

integrityJob -> ledgerDb "Reads entries and balances, and stores check results in" "SQL"

eventPublisher -> ledgerDb "Reads new outbox events from" "SQL"
eventPublisher -> simulator "Sends balance-changed events to" "Webhooks/HTTPS"
