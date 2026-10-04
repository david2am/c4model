// c1.dsl — System-level model elements (people, software systems, relationships)
// Included into workspace.dsl. No workspace{} wrapper here.

// ---------- Member credit union side ----------
group "Member Credit Union" {
    member = person "Credit Union Member" "Person or business with an account at a member credit union, sending or receiving payments."
    cuOps = person "Credit Union Payments Staff" "Staff at a member credit union who track payments, returns, and exceptions."
    cuTreasury = person "Credit Union Treasury Officer" "Manages the credit union's cash and liquidity, and needs to know settlement positions in real time."

    cuDigital = softwareSystem "Credit Union Digital Banking" "Online and mobile banking used by members to make payments and view balances." "External"
    cuCore = softwareSystem "Credit Union Core Processor" "System of record for the credit union's member accounts, balances, and transactions." "External"
}

// ---------- CorporateOne side ----------
group "CorporateOne" {
    coOps = person "CorporateOne Payment Operations" "Staff who monitor payment flow across all member credit unions and resolve exceptions."
    coFinance = person "CorporateOne Finance and Settlement Staff" "Review ledger balances, investigate differences, and approve manual adjustments."
    coAuditor = person "Auditor / Compliance Officer" "Reviews the history of entries and reconciliation results. Read-only access."

    platform = softwareSystem "Payment Orchestration Platform" "Receives payment requests from member credit unions, validates and routes them to the right payment network, and monitors liquidity and settlement in real time." "In Scope" {
        orchestratorApi = container "Orchestrator API" "Accepts payment requests and network answers. Saves each one together with a work item in a single transaction, ignores duplicates, and serves the read-only operations pages." "ASP.NET Core" "App"
        paymentWorker = container "Payment Worker" "Picks up work items and moves each payment through its steps: screen, reserve, send, confirm, post, notify. Retries safely, times out silent networks, and releases holds on failure." ".NET Worker Service" "App"
        platformDb = container "Platform Database" "Stores payments and their state history, idempotency keys, the work item queue, and raw network messages." "Azure SQL Database" "Database"
    }

    coLedger = softwareSystem "CorporateOne Settlement Accounts" "CorporateOne's ledger of member credit union accounts and settlement positions." "Internal" {
        ledgerService = container "Ledger Service" "Only component that changes balances. Holds, posts, and releases funds, rejects overdrafts, ignores duplicate requests, and serves the read-only dashboard pages." "ASP.NET Core" "App"
        integrityJob = container "Integrity Check Job" "Runs on a schedule and checks that debits equal credits, balances match entries, and no holds are stuck." ".NET Worker Service" "App"
        eventPublisher = container "Event Publisher" "Reads new entries from an outbox table and sends balance-changed events. Stretch goal." ".NET Worker Service" "Stretch"
        ledgerDb = container "Ledger Database" "Source of truth. Stores accounts, the permanent journal, balances, holds, idempotency keys, outbox events, and integrity check results." "Azure SQL Database" "Database"
    }
}

// ---------- External services ----------
fedServices = softwareSystem "Federal Reserve Payment Services" "Fed-operated services that move and settle money: FedNow (instant), FedACH (batch), and Fedwire (high value)." "External"
fedAccount = softwareSystem "Federal Reserve Account Services" "Provides statements and balance information for CorporateOne's master account at the Fed." "External"
rtpNetwork = softwareSystem "RTP Network" "Real-time payment network operated by The Clearing House." "External"
screening = softwareSystem "Sanctions and Fraud Screening" "Third-party service that checks payments against sanctions lists and fraud signals." "External"
coreSystems = softwareSystem "Corporate Core / General Ledger" "CorporateOne's accounting system for financial statements and reporting." "Internal"
identity = softwareSystem "Identity Provider" "Signs in CorporateOne staff and issues access tokens." "External"

// ---------- System-level relationships ----------
member -> cuDigital "Sends payments and checks balances using"
cuDigital -> cuCore "Reads accounts and requests transactions from"

cuCore -> platform "Submits payment requests to"
platform -> cuCore "Reports payment status and returns to"

cuOps -> platform "Tracks payments and resolves exceptions using"
cuTreasury -> platform "Monitors liquidity and settlement position using"
coOps -> platform "Monitors all payment activity and handles exceptions using"

platform -> coLedger "Checks funds and posts settlement entries to"
platform -> screening "Screens payments with"
platform -> fedServices "Sends payments to and receives confirmations from"
platform -> rtpNetwork "Sends payments to and receives confirmations from"

coFinance -> coLedger "Reviews balances and approves adjustments using"
coAuditor -> coLedger "Reviews entry history and reconciliation using"
coLedger -> fedAccount "Downloads daily statements from"
coLedger -> coreSystems "Sends summarized entries to"
