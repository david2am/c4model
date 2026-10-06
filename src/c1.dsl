// c1.dsl — System-level model elements (people, software systems, relationships)
// Included into workspace.dsl. No workspace{} wrapper here.

// ---------- Member credit union side ----------
group "Member Credit Union" {
    member = person "Credit Union Member" "Person or business with an account at a member credit union, sending or receiving payments. Initiates outbound payments via digital banking and receives inbound credits."
    cuOps = person "Credit Union Payments Staff" "Track payments, returns, and exceptions for their own credit union. Download statements and reports."
    cuTreasury = person "Credit Union Treasury Officer" "Manages the credit union's cash and liquidity. Monitors real-time settlement positions and available funds to ensure intraday liquidity."

    cuDigital = softwareSystem "Credit Union Digital Banking" "Online and mobile banking used by members to initiate payments, check balances, and view transaction history." "External"
    cuCore = softwareSystem "Credit Union Core Processor" "System of record for the credit union's member accounts, balances, and transactions. Receives inbound credits and payment results via webhook notifications." "External"
}

// ---------- OnePlatform side ----------
group "OnePlatform" {
    coOps = person "OnePlatform Payment Operations" "Monitor payment flow across all member credit unions and resolve live exceptions including timeouts, network rejections, and worker failures."
    coFinance = person "OnePlatform Finance and Settlement Staff" "Investigate reconciliation breaks, propose correcting entries, and review daily reports. Subject to two-person rule for corrections."
    coCompliance = person "Auditor / Compliance Officer" "Review entry history, reconciliation results, and regulatory reports. Read-only access."

    platform = softwareSystem "Clearing Platform" "Handles clearing: receives payment requests from credit union cores, screens them, reserves settlement funds, routes payment messages to the networks, tracks network answers, posts final entries, and notifies credit union cores of results. Handles inbound credits from networks." "In Scope" {

        apim = container "API Gateway" "Secured entry point: authenticates callers, enforces rate limits, routes inbound payment requests and webhook callbacks from networks, and serves read-only operations and reconciliation APIs." "Azure API Management" "Gateway"

        orchestratorApi = container "Orchestrator API" "Accepts payment requests, saves each one with an idempotency key and a work item in a single transaction, ignores duplicates, serves operations dashboard pages, and exposes payment records for reconciliation." "ASP.NET Core" "App"

        paymentWorker = container "Payment Worker" "Picks up work items and drives each payment through its lifecycle: screen → reserve → route → send → confirm → post → notify. Also handles inbound credits from networks. Retries safely on transient failures, times out silent networks, releases holds on failure, and moves unrecoverable items to the dead-letter table." ".NET Worker Service" "App"

        isoService = container "ISO 20022 Message Service" "Builds and parses ISO 20022 messages (pacs.008, pacs.004, pacs.002) so no other container needs to know the message formats. Shared by outbound and inbound payment flows." ".NET Worker Service" "App"

        keyVault = container "Key Vault" "Stores network certificates (mTLS for FedNow), private keys, and API secrets. Required by FedNow before going live." "Azure Key Vault" "Vault"

        platformDb = container "Platform Database" "Stores payments and their full state history, idempotency keys, the work item queue, dead-letter entries, raw network messages (inbound and outbound), and return transactions." "Azure SQL Database" "Database"
    }

    settlement = softwareSystem "Settlement Platform" "Real-time record of member credit union balances. Handles holds, posts, and releases; rejects overdrafts; enforces per-credit-union data isolation; accepts correcting entries (idempotent, with approver identity attached); and serves entries and balances as of a configurable cut-off time." "In Scope" {

        ledgerService = container "Ledger Service" "Only component that changes balances. Holds, posts, and releases funds; rejects overdrafts; ignores duplicate requests; accepts correcting entries (idempotent, approver identity required in payload); enforces per-credit-union data isolation so each CU only sees its own entries; and serves entries and balances as of the current business day cut-off time." "ASP.NET Core" "App"

        cutoffScheduler = container "Business Day Scheduler" "Manages the business day boundary. Marks the end-of-day cut-off time in the ledger, ensuring entries after cut-off are attributed to the next business day. Drives the collector and reconEngine sequencing downstream." "Azure Functions" "App"

        integrityJob = container "Integrity Check Job" "Checks the ledger against itself: debits equal credits, balances match the sum of entries, no holds are stuck open past their timeout. Alerts operations on any discrepancy. Does not compare across systems." ".NET Worker Service" "App"

        eventPublisher = container "Event Publisher" "Reads committed entries from an outbox table and publishes balance-changed events to the message bus exactly once. Stretch goal — the Data Collector polls the Ledger Service directly in the MVP." ".NET Worker Service" "Stretch"

        settlementBus = container "Settlement Event Bus" "Carries balance-changed events from the Event Publisher to downstream consumers such as the liquidity monitor." "Azure Service Bus" "Queue,Stretch"

        ledgerDb = container "Ledger Database" "Source of truth. Stores accounts, the permanent journal (immutable entries), balances, holds, idempotency keys, outbox events, integrity check results, and the current business day marker." "Azure SQL Database" "Database"
    }

    postSettlement = softwareSystem "Post-Settlement Platform" "Runs after settlement cut-off to reconcile numbers across systems, manage exceptions and corrections, produce member statements and regulatory reports, and feed the Corporate General Ledger. Each accounting export carries a batch ID so the GL never receives the same day twice." "Future" {
        portal = container "Back-Office Portal" "Lets staff view reconciliation results, work cases, propose and approve corrections, and download reports. Enforces per-credit-union access." "Blazor WebAssembly" "WebApp,Future"
        api = container "Post-Settlement API" "Serves the portal. Manages cases and corrections, enforces the two-person rule and per-credit-union access controls, and sends approved corrections to the Ledger Service with approver identity in the payload." "ASP.NET Core" "App,Future"
        collector = container "Data Collector" "Triggered by the Business Day Scheduler cut-off event. Polls the Clearing Platform and Settlement Platform APIs for payment records and ledger entries as of the cut-off time. Downloads statements from FedLine API (FedNow) and settlement reports from TCH via SFTP (RTP). Stores originals in the archive untouched and a normalized copy in the database." ".NET Worker Service" "Worker,Future"
        reconEngine = container "Reconciliation Engine" "Runs after the collector completes for the day. Compares platform vs. ledger, ledger vs. Fed statement, and platform vs. RTP report. Creates a break record for every difference found." ".NET Worker Service" "Worker,Future"
        reportGenerator = container "Report Generator" "Builds member statements, activity reports, and regulatory reports from a frozen daily snapshot, and delivers them." "Azure Functions" "Worker,Future"
        accountingExporter = container "Accounting Exporter" "Sends daily summarized debit/credit entries to the corporate general ledger. Each export carries a batch ID (idempotent). Retries on GL unavailability; records failed export attempts in the database for manual retry." "Azure Functions" "Worker,Future"
        db = container "Post-Settlement Database" "Stores normalized payment and ledger data, recon matches and breaks, cases, correction approvals, report records, job status, and daily totals ready for export. Only fully reconciled days enter the export set." "Azure SQL Database" "Database,Future"
        archive = container "Immutable Archive" "Keeps original Fed statements, RTP reports, and generated reports unchanged for the required retention period. Written by the collector (originals) and report generator (produced reports) — these are different write paths with different retention policies." "Azure Blob Storage" "Archive,Future"
    }

    monitoring = softwareSystem "Monitoring and Alerting" "Centralizes metrics, logs, distributed traces, and alerts for all three platforms. Notifies payment operations of worker failures, dead-letter growth, network timeouts, and integrity check failures." "Internal"

    generalLedger = softwareSystem "Corporate General Ledger" "Accounting record for OnePlatform's financial statements. Receives idempotent daily summarized entries from the Post-Settlement Platform after reconciliation." "Internal"
}

// ---------- External ----------
fedServices = softwareSystem "Federal Reserve Payment Services" "FedNow real-time payment network. Movements settle against OnePlatform's master account at the Fed. FedLine API provides account statements for daily reconciliation. Requires mTLS with Fed-issued certificates." "External"
rtpNetwork = softwareSystem "RTP Network (TCH)" "Real-time payment network operated by The Clearing House. Settlement moves positions in OnePlatform's prefunded account held at TCH — a different settlement model from FedNow. Provides daily settlement reports via SFTP." "External"
screening = softwareSystem "Sanctions and Fraud Screening" "Third-party service that checks payments against OFAC sanctions lists and fraud signals. Blocks the payment and rejects it to the sender if unavailable or if a match is found — it is never silently bypassed." "External"
regulator = softwareSystem "Regulator (NCUA)" "Receives required regulatory reports submitted by the Post-Settlement Platform." "External"
identity = softwareSystem "Identity Provider" "Signs in OnePlatform staff and issues short-lived access tokens. All staff-facing APIs validate tokens before serving any request." "External"

// ---------- Outbound payments ----------
member -> cuDigital "Initiates outbound payments and checks balances using"
cuDigital -> cuCore "Reads accounts and requests transactions from"
cuCore -> platform "Submits outbound payment requests to" "HTTPS/JSON"
platform -> screening "Screens every payment before routing — blocks if unavailable" "HTTPS/JSON"
platform -> settlement "Reserves, posts, and releases settlement funds with" "HTTPS/JSON, OAuth2 client credentials"
platform -> fedServices "Sends outbound FedNow payments to and receives network answers from" "ISO 20022 pacs.008 / mTLS"
platform -> rtpNetwork "Sends outbound RTP payments to and receives network answers from" "ISO 20022 pacs.008 / mTLS"

// ---------- Inbound credits ----------
fedServices -> platform "Delivers inbound FedNow credits to" "ISO 20022 pacs.008 / mTLS"
rtpNetwork -> platform "Delivers inbound RTP credits to" "ISO 20022 pacs.008 / mTLS"
platform -> cuCore "Notifies credit union cores of payment results and inbound credits via" "Webhooks/HTTPS"
member -> cuDigital "Views received payment in account balance via"

// ---------- Returns (R-transactions) ----------
fedServices -> platform "Delivers FedNow return messages (pacs.004) to" "ISO 20022 pacs.004 / mTLS"
rtpNetwork -> platform "Delivers RTP return messages to" "ISO 20022 / mTLS"
platform -> settlement "Reverses hold or credits back on return" "HTTPS/JSON, OAuth2 client credentials"

// ---------- Live monitoring ----------
cuOps -> platform "Tracks payments and resolves exceptions using" "HTTPS"
cuTreasury -> settlement "Monitors real-time settlement positions and available funds using" "HTTPS"
coOps -> platform "Monitors all payment activity across all credit unions using" "HTTPS"
platform -> monitoring "Emits metrics, logs, and alerts to"
settlement -> monitoring "Emits metrics, logs, and alerts to"

// ---------- Authentication ----------
platform -> identity "Validates staff tokens with" "OpenID Connect"
settlement -> identity "Validates staff tokens with" "OpenID Connect"
postSettlement -> identity "Validates staff tokens with" "OpenID Connect"

// ---------- After settlement ----------
settlement -> postSettlement "Notifies of cut-off completion via Business Day Scheduler event"
postSettlement -> platform "Reads payment records as of cut-off time from" "HTTPS/JSON, OAuth2 client credentials"
postSettlement -> settlement "Reads entries and balances as of cut-off time from" "HTTPS/JSON, OAuth2 client credentials"
postSettlement -> settlement "Sends approved correcting entries with approver identity to" "HTTPS/JSON, OAuth2 client credentials"
postSettlement -> fedServices "Downloads FedNow account statements from" "FedLine API / HTTPS"
postSettlement -> rtpNetwork "Downloads RTP settlement reports from" "SFTP"
postSettlement -> generalLedger "Sends idempotent daily summarized entries to" "HTTPS/JSON"
postSettlement -> regulator "Submits regulatory reports to" "HTTPS / SFTP"
postSettlement -> cuCore "Sends member statements and activity reports to" "SFTP"

coFinance -> postSettlement "Investigates reconciliation breaks and proposes corrections using"
coCompliance -> postSettlement "Reviews entry history and reports using"
cuOps -> postSettlement "Downloads statements and reports from"
