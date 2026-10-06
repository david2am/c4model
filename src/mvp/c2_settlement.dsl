// c2_settlement.dsl — Settlement Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'settlement'.

// ---------- People (MVP demo roles) ----------
// Note: 'financeViewer' is a demo stand-in. In production, coFinance and cuTreasury
// use the same ledgerService with per-credit-union RBAC enforced at the API layer.
financeViewer = person "Finance Viewer (Demo)" "Demo persona for MVP. Views balances, holds, and entry history. Superseded by coFinance and cuTreasury in production with per-credit-union data isolation enforced." "Test Tool"

// ---------- Test tools ----------
simulator = softwareSystem "Payment Simulator" "Test tool that plays the role of the Clearing Platform. Sends reserve, post, and release requests including duplicates, simultaneous calls, and overdraft attempts to verify rejection. Also used to simulate correction entries." "Test Tool"

// ---------- Relationships: people ----------
financeViewer -> ledgerService "Views balances, holds, and entry history using" "HTTPS"
// cuTreasury reads available funds via the Clearing API (orchestratorApi) which proxies to ledgerService.
// Direct read of the ledger by treasury staff is intentionally routed through the platform APIM.

// ---------- Relationships: authentication ----------
ledgerService -> identity "Validates staff tokens with" "OpenID Connect"
// integrityJob and eventPublisher connect to ledgerDb directly via managed identity (no user token needed).
// cutoffScheduler uses a managed identity to write the business day marker to ledgerDb.

// ---------- Relationships: inbound from Clearing (main write paths) ----------
simulator -> ledgerService "Reserves funds, posts final entries, releases holds, sends overdraft attempts, and submits correction entries with approver identity" "HTTPS/JSON"
// In production, paymentWorker calls ledgerService — declared in c2_clearing.dsl.

// ---------- Relationships: inside the settlement platform ----------
ledgerService -> ledgerDb "Reads and writes entries, balances, holds, idempotency keys, and outbox events atomically" "SQL"

cutoffScheduler -> ledgerDb "Writes the end-of-day cut-off marker to begin the next business day" "SQL"
// This marker is what makes ledgerService serve entries 'as of cut-off time' to downstream readers.

integrityJob -> ledgerDb "Reads entries and balances, verifies debits = credits, balances = sum of entries, no stuck holds; stores check results" "SQL"

// ---------- Relationships: event publishing (stretch goal) ----------
// MVP: Data Collector polls ledgerService directly instead of consuming events.
// Stretch: eventPublisher reads from the outbox table and publishes to the bus.
eventPublisher -> ledgerDb "Reads committed outbox entries (new balance changes) from" "SQL"
eventPublisher -> settlementBus "Publishes balance-changed events exactly once to" "AMQP"
// settlementBus -> [liquidity monitor or other consumers] — wired when event consumers are built.

// ---------- Downstream consumers ----------
postSettlement -> ledgerService "Reads entries and balances as of cut-off time from" "HTTPS/JSON, OAuth2 client credentials"
postSettlement -> ledgerService "Sends approved correcting entries with approver identity in payload to" "HTTPS/JSON, OAuth2 client credentials"
