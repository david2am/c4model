// c2_post-settlement.dsl — Post-Settlement Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'postSettlement'.
// All external systems and most people are declared in c1.dsl.

// ---------- People ----------
// coApprover is the Finance Supervisor who approves corrections.
// Declared here (not c1.dsl) because the two-person rule is a post-settlement concern,
// but added as a C1-level relationship below so the approver is visible at context level.
coApprover = person "Finance Supervisor (Approver)" "Approves or rejects correcting entries proposed by coFinance. Must be a different person than the proposer — the two-person rule is enforced by the Post-Settlement API."

// ---------- System-level relationship (coApprover only appears in post-settlement) ----------
coApprover -> postSettlement "Approves or rejects correcting entries using"

// ---------- Relationships: people to portal ----------
coFinance -> portal "Investigates reconciliation breaks and proposes correcting entries using" "HTTPS"
coApprover -> portal "Reviews and approves or rejects proposed corrections using" "HTTPS"
coCompliance -> portal "Reviews entry history, reconciliation results, and regulatory reports using" "HTTPS"
cuOps -> portal "Downloads member statements and activity reports using" "HTTPS"

// ---------- Relationships: portal and API ----------
portal -> identity "Signs users in with" "OpenID Connect"
portal -> api "Requests reconciliation data, cases, corrections, and reports from" "HTTPS/JSON"
api -> identity "Validates tokens and enforces per-credit-union access controls with" "OpenID Connect"
api -> db "Reads recon results and stores cases, corrections, and approval records in" "SQL"
api -> archive "Reads generated report files from" "HTTPS"
api -> ledgerService "Sends approved correcting entries with approver identity in payload to" "HTTPS/JSON, OAuth2 client credentials"

// ---------- Relationships: collecting ----------
// Collector is triggered by the Business Day Scheduler cut-off event from the Settlement Platform.
// MVP: polls APIs directly. Stretch: consumes balance-changed events from Settlement Event Bus.
collector -> orchestratorApi "Reads payment records as of cut-off time from" "HTTPS/JSON, OAuth2 client credentials"
collector -> ledgerService "Reads entries and balances as of cut-off time from" "HTTPS/JSON, OAuth2 client credentials"
// FedNow statements arrive via the FedLine API (HTTPS) — not SFTP.
collector -> fedServices "Downloads FedNow account statements via FedLine API from" "HTTPS (FedLine API)"
// RTP settlement reports arrive via SFTP from TCH — different protocol from FedNow.
collector -> rtpNetwork "Downloads RTP settlement reports via SFTP from" "SFTP (TCH)"
collector -> db "Stores normalized payment and ledger data in" "SQL"
collector -> archive "Stores original Fed statements and RTP reports untouched in" "HTTPS"

// ---------- Relationships: reconciliation ----------
// reconEngine runs after the collector job completes for the day — sequenced by the cut-off event.
reconEngine -> db "Reads normalized data and writes match records and break records to" "SQL"

// ---------- Relationships: reporting ----------
reportGenerator -> db "Reads the frozen daily snapshot and stores report records in" "SQL"
reportGenerator -> archive "Stores generated member statements and regulatory reports in" "HTTPS"
// Statements delivered to credit union cores via SFTP (file format: PDF / structured CSV).
reportGenerator -> cuCore "Delivers member statements and activity reports to" "SFTP"
// Regulatory reports delivered to NCUA via HTTPS or SFTP depending on report type.
reportGenerator -> regulator "Submits regulatory reports to" "HTTPS / SFTP"

// ---------- Relationships: accounting ----------
// accountingExporter reads from daily totals already reconciled in db — never raw ledger data.
// Carries a batch ID per day; retries on GL unavailability and records failed attempts in db.
accountingExporter -> db "Reads reconciled daily totals and records export attempts in" "SQL"
accountingExporter -> generalLedger "Sends idempotent daily summarized entries (debit/credit) to" "HTTPS/JSON"
