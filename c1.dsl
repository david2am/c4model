// c1.dsl — System-level model elements (people, software systems, relationships)
// Included into workspace.dsl. No workspace{} wrapper here.

// ---------- Member credit union side ----------
group "Member Credit Union" {
    member = person "Credit Union Member" "Person or business with an account at a member credit union, sending or receiving payments."
    cuOps = person "Credit Union Payments Staff" "Track payments, returns, and exceptions for their own credit union."
    cuTreasury = person "Credit Union Treasury Officer" "Manages the credit union's cash and liquidity and needs to know settlement positions in real time."

    cuDigital = softwareSystem "Credit Union Digital Banking" "Online and mobile banking used by members to make payments and view balances." "External"
    cuCore = softwareSystem "Credit Union Core Processor" "System of record for the credit union's member accounts, balances, and transactions." "External"
}

// ---------- OnePlatform side ----------
group "OnePlatform" {
    coOps = person "OnePlatform Payment Operations" "Monitor payment flow across all member credit unions and resolve live exceptions."
    coFinance = person "OnePlatform Finance and Settlement Staff" "Investigate reconciliation differences, approve corrections, and review reports."
    coCompliance = person "Auditor / Compliance Officer" "Review history, reconciliation results, and regulatory reports. Read-only."

    platform = softwareSystem "Clearing Platform" "Handles clearing: receives payment requests, screens them, sends payment messages to the networks, and tracks results." "In Scope" {
        orchestratorApi = container "Orchestrator API" "Accepts payment requests and network answers. Saves each one together with a work item in a single transaction, ignores duplicates, serves the read-only operations pages, and exposes payment records for reconciliation." "ASP.NET Core" "App"
        paymentWorker = container "Payment Worker" "Picks up work items and moves each payment through its steps: screen, reserve, send, confirm, post, notify. Retries safely, times out silent networks, and releases holds on failure." ".NET Worker Service" "App"
        platformDb = container "Platform Database" "Stores payments and their state history, idempotency keys, the work item queue, and raw network messages." "Azure SQL Database" "Database"
    }

    settlement = softwareSystem "Settlement Platform" "Real-time record of member credit union balances. Handles holds, posts, and releases; rejects overdrafts; and keeps a full history of every entry." "In Scope" {
        ledgerService = container "Ledger Service" "Only component that changes balances. Holds, posts, and releases funds, rejects overdrafts, ignores duplicate requests, accepts correcting entries (idempotent, with approver identity), serves entries and balances as of a cut-off time, and serves the read-only dashboard pages." "ASP.NET Core" "App"
        integrityJob = container "Integrity Check Job" "Checks the ledger against itself: debits equal credits, balances match the sum of entries, and no holds are stuck. Does not compare across systems." ".NET Worker Service" "App"
        eventPublisher = container "Event Publisher" "Reads new entries from an outbox table and sends balance-changed events. Stretch goal — for the MVP the Data Collector polls the Ledger Service directly." ".NET Worker Service" "Stretch"
        ledgerDb = container "Ledger Database" "Source of truth. Stores accounts, the permanent journal, balances, holds, idempotency keys, outbox events, and integrity check results." "Azure SQL Database" "Database"
    }

    postSettlement = softwareSystem "Post-Settlement Platform" "Checks that everything matches after settlement: reconciles, manages exceptions, produces member statements and reports, feeds accounting, and keeps the archive." "Future" {
        portal = container "Back-Office Portal" "Lets staff view reconciliation results, work cases, propose and approve corrections, and download reports." "Blazor WebAssembly" "WebApp,Future"
        api = container "Post-Settlement API" "Serves the portal. Manages cases and corrections, enforces the two-person rule and per-credit-union access, and sends approved corrections to the ledger." "ASP.NET Core" "App,Future"
        collector = container "Data Collector" "Polls the Clearing Platform and Settlement Platform APIs for payment records and ledger entries as of a cut-off time. Downloads statements and reports from the Fed and RTP. Stores originals untouched and a normalized copy." ".NET Worker Service" "Worker,Future"
        reconEngine = container "Reconciliation Engine" "Checks across systems: compares platform vs. ledger, ledger vs. Fed statement, and platform vs. network report. Creates a break for every difference found." ".NET Worker Service" "Worker,Future"
        reportGenerator = container "Report Generator" "Builds member statements, activity reports, and regulatory reports from a frozen snapshot, and delivers them." "Azure Functions" "Worker,Future"
        accountingExporter = container "Accounting Exporter" "Sends daily summarized entries to the corporate general ledger. Each export carries a batch ID so the GL never receives the same day twice." "Azure Functions" "Worker,Future"
        db = container "Post-Settlement Database" "Stores normalized data, matches, breaks, cases, correction approvals, report records, job status, and daily totals ready for export. Only reconciled days are included in the export set." "Azure SQL Database" "Database,Future"
        archive = container "Immutable Archive" "Keeps original statements, network reports, and generated reports unchanged for the required retention period." "Azure Blob Storage" "Archive,Future"
    }

    generalLedger = softwareSystem "Corporate General Ledger" "Accounting record for OnePlatform's financial statements. Receives summarized daily entries from the Post-Settlement Platform after reconciliation." "Internal"
}

// ---------- External ----------
fedServices = softwareSystem "Federal Reserve Payment Services" "Fed services that move and settle money, such as FedNow. Also provides account statements." "External"
rtpNetwork = softwareSystem "RTP Network" "Real-time payment network operated by The Clearing House. Also provides settlement reports." "External"
screening = softwareSystem "Sanctions and Fraud Screening" "Third-party service that checks payments against sanctions lists and fraud signals." "External"
regulator = softwareSystem "Regulator (NCUA)" "Receives required regulatory reports." "External"
identity = softwareSystem "Identity Provider" "Signs in OnePlatform staff and issues access tokens." "External"

// ---------- Live payments ----------
member -> cuDigital "Sends payments and checks balances using"
cuDigital -> cuCore "Reads accounts and requests transactions from"

cuCore -> platform "Submits payment requests to"
platform -> cuCore "Reports payment results to"

platform -> screening "Screens payments with"
platform -> fedServices "Sends payments to and receives answers from"
platform -> rtpNetwork "Sends payments to and receives answers from"
platform -> settlement "Asks to settle (reserve, post, release) with"

// ---------- Live monitoring ----------
cuOps -> platform "Tracks payments and resolves exceptions using"
cuTreasury -> platform "Monitors liquidity and settlement position using"
coOps -> platform "Monitors all payment activity using"

// ---------- Authentication ----------
platform -> identity "Validates staff tokens with"
settlement -> identity "Validates staff tokens with"

// ---------- After settlement ----------
postSettlement -> platform "Reads payment records from"
postSettlement -> settlement "Reads entries and balances from, and sends correcting entries to"
postSettlement -> fedServices "Downloads account statements from"
postSettlement -> rtpNetwork "Downloads settlement reports from"
postSettlement -> generalLedger "Sends summarized entries to"
postSettlement -> regulator "Submits regulatory reports to"
postSettlement -> cuCore "Sends statements and activity reports to"

coFinance -> postSettlement "Investigates differences and approves corrections using"
coCompliance -> postSettlement "Reviews history and reports using"
cuOps -> postSettlement "Downloads statements and reports from"
