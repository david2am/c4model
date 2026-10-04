workspace "CorporateOne Settlement Accounts - MVP" "Smallest useful version of the settlement ledger, built in 4 weeks." {

    model {

        # ---------- People ----------
        coFinance = person "CorporateOne Finance and Settlement Staff" "View balances, holds, and the history of entries for each member credit union."

        # ---------- Other systems ----------
        platform = softwareSystem "Payment Orchestration Platform" "Routes payments to the networks. In the MVP this can be a simple test client." "Later"
        identity = softwareSystem "Identity Provider" "Signs in CorporateOne staff and issues access tokens." "External"

        # ---------- The system we are zooming into ----------
        ledger = softwareSystem "CorporateOne Settlement Accounts" "Ledger of member credit union accounts: balances, holds, and the full history of every entry." "In Scope" {

            ledgerService = container "Ledger Service" "Only component that changes balances. Holds, posts, and releases funds, rejects overdrafts, ignores duplicate requests, and serves the finance dashboard pages." "ASP.NET Core on Azure App Service" "App"

            ledgerDb = container "Ledger Database" "Source of truth. Stores accounts, the permanent journal of entries, balances, holds, and idempotency keys." "Azure SQL Database" "Database"
        }

        # ---------- Relationships ----------
        coFinance -> ledgerService "Views balances and entry history using" "HTTPS"
        platform -> ledgerService "Reserves funds, posts entries, releases holds, and queries balances with" "HTTPS/JSON"
        ledgerService -> identity "Validates sign-ins and tokens with" "OpenID Connect"
        ledgerService -> ledgerDb "Reads and writes entries, balances, holds, and idempotency keys" "SQL"
    }

    views {

        container ledger "Containers" {
            include *
            autoLayout lr
            title "CorporateOne Settlement Accounts MVP - Containers"
            description "Two containers: one service and one database."
        }

        dynamic ledger "ReserveAndPost" "How funds are held, then posted, for one outgoing payment." {
            platform -> ledgerService "1. Asks to reserve funds (with a unique request ID)"
            ledgerService -> ledgerDb "2. Checks duplicate ID, checks available funds, creates hold"
            platform -> ledgerService "3. After the network confirms, asks to post"
            ledgerService -> ledgerDb "4. Converts hold into permanent entries and updates balance"
            coFinance -> ledgerService "5. Sees the new balance and history"
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
            element "Later" {
                background #bbbbbb
                color #ffffff
                border Dashed
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #1168bd
                color #ffffff
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