workspace "CorporateOne Settlement Accounts - Demo" "Demo version of the settlement ledger, focused on backend correctness." {

    model {

        # ---------- People ----------
        viewer = person "Finance Viewer (Demo: Manager)" "Views balances, holds, and entry history for each member credit union."
        developer = person "Developer (Demo Presenter)" "Runs the simulator and the integrity check to show the ledger is safe."

        # ---------- Other systems ----------
        simulator = softwareSystem "Payment Simulator" "Test tool that plays the role of the Payment Orchestration Platform. Sends reserve, post, and release requests, including duplicates and simultaneous ones." "Test Tool"
        identity = softwareSystem "Identity Provider" "Signs in staff and issues access tokens." "External"

        # ---------- The system we are zooming into ----------
        ledger = softwareSystem "CorporateOne Settlement Accounts" "Ledger of member credit union accounts: balances, holds, and the full history of every entry." "In Scope" {

            ledgerService = container "Ledger Service" "Only component that changes balances. Holds, posts, and releases funds, rejects overdrafts, ignores duplicate requests, and serves the read-only dashboard pages." "ASP.NET Core" "App"

            integrityJob = container "Integrity Check Job" "Runs on a schedule and checks that debits equal credits, balances match entries, and no holds are stuck." ".NET Worker Service" "App"

            eventPublisher = container "Event Publisher" "Reads new entries from an outbox table and sends balance-changed events. Stretch goal." ".NET Worker Service" "Stretch"

            ledgerDb = container "Ledger Database" "Source of truth. Stores accounts, the permanent journal, balances, holds, idempotency keys, outbox events, and integrity check results." "Azure SQL Database" "Database"
        }

        # ---------- Relationships ----------
        viewer -> ledgerService "Views balances and entry history using" "HTTPS"
        developer -> simulator "Runs load and duplicate-request tests with" "Command line"
        developer -> integrityJob "Triggers on demand and reviews results of" "Command line"

        simulator -> ledgerService "Reserves funds, posts entries, releases holds, and queries balances with" "HTTPS/JSON"
        ledgerService -> identity "Validates sign-ins and tokens with" "OpenID Connect"
        ledgerService -> ledgerDb "Reads and writes entries, balances, holds, and idempotency keys" "SQL"

        integrityJob -> ledgerDb "Reads entries and balances, and stores check results in" "SQL"

        eventPublisher -> ledgerDb "Reads new outbox events from" "SQL"
        eventPublisher -> simulator "Sends balance-changed events to" "Webhooks/HTTPS"
    }

    views {

        container ledger "Containers" {
            include *
            autoLayout lr
            title "CorporateOne Settlement Accounts Demo - Containers"
            description "A small ledger service, a database, an integrity check, and an optional event publisher."
        }

        dynamic ledger "ReserveAndPost" "How funds are held, then posted, and how a duplicate is ignored." {
            simulator -> ledgerService "1. Asks to reserve funds (unique request ID)"
            ledgerService -> ledgerDb "2. Checks the ID, locks the account, checks funds, creates hold"
            simulator -> ledgerService "3. Sends the same request again by mistake"
            ledgerService -> ledgerDb "4. Finds the ID, returns the first result, changes nothing"
            simulator -> ledgerService "5. Asks to post the held funds"
            ledgerService -> ledgerDb "6. Turns hold into permanent entries, updates balance"
            viewer -> ledgerService "7. Sees the new balance and history"
            autoLayout lr
        }

        dynamic ledger "IntegrityCheck" "How the ledger proves it is still correct." {
            developer -> integrityJob "1. Starts the check"
            integrityJob -> ledgerDb "2. Reads entries and balances, stores the result"
            viewer -> ledgerService "3. Sees the check result on the dashboard"
            ledgerService -> ledgerDb "4. Reads the latest result"
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
            element "Test Tool" {
                background #bbbbbb
                color #ffffff
                border dashed
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #1168bd
                color #ffffff
            }
            element "Stretch" {
                background #85bbf0
                color #000000
                border dashed
            }
            element "Database" {
                shape Cylinder
                background #0078d4
                color #ffffff
            }
            relationship "Relationship" {
                color #707070
            }
        }
    }
}