workspace "CorporateOne Settlement Accounts - Containers" "Container view of the settlement ledger for member credit unions." {

    model {

        # ---------- People ----------
        coFinance = person "CorporateOne Finance and Settlement Staff" "Review ledger balances, investigate differences, and approve manual adjustments."
        coAuditor = person "Auditor / Compliance Officer" "Reviews the history of entries and reconciliation results. Read-only access."

        # ---------- Other systems ----------
        platform = softwareSystem "Payment Orchestration Platform" "Receives payment requests, routes them to payment networks, and monitors liquidity." "Internal"
        fedAccount = softwareSystem "Federal Reserve Account Services" "Provides statements and balance information for CorporateOne's master account at the Fed." "External"
        coreSystems = softwareSystem "Corporate Core / General Ledger" "CorporateOne's accounting system for financial statements and reporting." "Internal"
        identity = softwareSystem "Identity Provider" "Signs in CorporateOne staff and issues access tokens." "External"

        # ---------- The system we are zooming into ----------
        ledger = softwareSystem "CorporateOne Settlement Accounts" "Ledger of member credit union accounts: balances, holds, and the full history of every entry." "In Scope" {

            # Entry point
            ledgerApi = container "Ledger API" "Secured entry point for the platform and the back-office portal. Checks identity and permissions." "Azure API Management" "Gateway"

            # Core services
            ledgerService = container "Ledger Service" "Only component allowed to change balances. Creates holds, posts entries, releases holds, and rejects anything that would overdraw an account." "ASP.NET Core"
            positionService = container "Position Query Service" "Answers read questions quickly: current balance, funds on hold, and available funds for each credit union." "ASP.NET Core"
            reconService = container "Reconciliation Service" "Compares the ledger with Federal Reserve statements each day and reports differences." ".NET Worker Service"
            adjustmentService = container "Adjustment Service" "Handles manual corrections. Requires two different people: one to request and one to approve." "ASP.NET Core"
            eventPublisher = container "Event Publisher" "Reads new ledger changes and sends them to the message bus exactly once." ".NET Worker Service"
            glExporter = container "General Ledger Export" "Sends daily summarized entries to the corporate general ledger for accounting and reporting." "Azure Functions"

            # Back-office UI
            backOffice = container "Back-Office Portal" "Lets finance staff and auditors search entries, view balances, handle differences, and approve adjustments." "Blazor WebAssembly" "WebApp"

            # Data and infrastructure
            ledgerDb = container "Ledger Database" "Source of truth. Stores the journal (permanent entries), balances, holds, and adjustment approvals." "Azure SQL Database" "Database"
            readReplica = container "Read Replica" "Read-only copy of the ledger database used for balance queries and reports, so reads never slow down writes." "Azure SQL Database" "Database"
            archive = container "Statement and Message Archive" "Long-term, unchangeable storage for Fed statements, reconciliation reports, and audit exports." "Azure Blob Storage" "Archive"
            serviceBus = container "Message Bus" "Carries ledger events, such as balance changed or hold released." "Azure Service Bus" "Queue"
        }

        # ---------- Relationships: people ----------
        coFinance -> backOffice "Reviews balances and approves adjustments using" "HTTPS"
        coAuditor -> backOffice "Reviews entry history and reconciliation using" "HTTPS"
        backOffice -> identity "Signs users in with" "OpenID Connect"
        backOffice -> ledgerApi "Requests ledger data from" "HTTPS/JSON"

        # ---------- Relationships: entry point ----------
        platform -> ledgerApi "Reserves funds, posts entries, and queries positions with" "HTTPS/JSON"
        ledgerApi -> ledgerService "Forwards changes to balances to" "HTTPS"
        ledgerApi -> positionService "Forwards balance and position queries to" "HTTPS"
        ledgerApi -> adjustmentService "Forwards manual adjustment requests to" "HTTPS"
        ledgerApi -> identity "Validates tokens with" "OpenID Connect"

        # ---------- Relationships: writes ----------
        ledgerService -> ledgerDb "Writes entries, balances, and holds in one transaction" "SQL"
        adjustmentService -> ledgerService "Asks to post approved adjustments" "HTTPS"
        adjustmentService -> ledgerDb "Stores adjustment requests and approvals in" "SQL"

        # ---------- Relationships: reads ----------
        ledgerDb -> readReplica "Copies data to" "Azure SQL geo-replication"
        positionService -> readReplica "Reads balances and holds from" "SQL"

        # ---------- Relationships: events ----------
        eventPublisher -> ledgerDb "Reads new committed changes from" "SQL"
        eventPublisher -> serviceBus "Publishes ledger events to" "AMQP"
        serviceBus -> platform "Delivers settlement events to" "AMQP"

        # ---------- Relationships: reconciliation ----------
        reconService -> fedAccount "Downloads daily statements from" "HTTPS / SFTP"
        reconService -> readReplica "Reads ledger totals from" "SQL"
        reconService -> archive "Stores statements and reports in" "HTTPS"
        reconService -> serviceBus "Publishes difference alerts to" "AMQP"

        # ---------- Relationships: accounting ----------
        glExporter -> readReplica "Reads daily totals from" "SQL"
        glExporter -> coreSystems "Sends summarized entries to" "HTTPS/JSON"
    }

    views {

        container ledger "Containers" {
            include *
            autoLayout lr
            title "CorporateOne Settlement Accounts - Containers"
            description "The building blocks of the ledger and how they connect to staff and other systems."
        }

        dynamic ledger "ReserveAndPost" "How funds are held, then posted, for one outgoing payment." {
            platform -> ledgerApi "1. Asks to reserve funds"
            ledgerApi -> ledgerService "2. Forwards request"
            ledgerService -> ledgerDb "3. Checks available funds, creates hold"
            ledgerApi -> platform "4. Confirms hold"
            platform -> ledgerApi "5. After network confirms, asks to post"
            ledgerApi -> ledgerService "6. Forwards request"
            ledgerService -> ledgerDb "7. Converts hold into permanent entries"
            eventPublisher -> ledgerDb "8. Sees the new change"
            eventPublisher -> serviceBus "9. Publishes balance changed"
            serviceBus -> platform "10. Delivers event to liquidity monitor"
            autoLayout lr
        }

        dynamic ledger "DailyReconciliation" "How the ledger is checked against the Federal Reserve each day." {
            reconService -> fedAccount "1. Downloads daily statement"
            reconService -> readReplica "2. Reads ledger totals"
            reconService -> archive "3. Stores statement and report"
            reconService -> serviceBus "4. Publishes alert if there is a difference"
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "In Scope" {
                background #0b5394
                color #ffffff
            }
            element "Internal" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #1168bd
                color #ffffff
            }
            element "Gateway" {
                background #0078d4
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "Queue" {
                shape Pipe
                background #0078d4
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #0078d4
                color #ffffff
            }
            element "Archive" {
                shape Folder
                background #5c5c5c
                color #ffffff
            }
            relationship "Relationship" {
                color #707070
            }
        }
    }
}