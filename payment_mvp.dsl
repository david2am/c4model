workspace "CorporateOne Payment Orchestration - MVP Demo" "Demo version of the payment orchestrator, focused on reliable step-by-step processing." {

    model {

        # ---------- People ----------
        viewer = person "Operations Viewer (Demo: Manager)" "Views payments, their status, and the available funds of each credit union."
        developer = person "Developer (Demo Presenter)" "Runs the simulators and triggers failure scenarios to show the platform recovers."

        # ---------- Other systems ----------
        coreSim = softwareSystem "Credit Union Core Simulator" "Test tool that plays the credit union core. Submits payment requests, sends duplicates, and receives status notifications." "Test Tool"
        networkSim = softwareSystem "Payment Network Simulator" "Test tool that plays FedNow. Accepts, rejects, delays, or ignores payments, and can send duplicate answers." "Test Tool"
        screeningStub = softwareSystem "Sanctions Screening Stub" "Test tool that rejects payments for names on a small test list." "Test Tool"
        ledger = softwareSystem "CorporateOne Settlement Accounts" "Demo ledger that reserves, posts, and releases funds with duplicate protection." "Internal"

        # ---------- The system we are zooming into ----------
        platform = softwareSystem "Payment Orchestration Platform" "Receives payment requests, screens them, reserves funds, sends them to the network, and reports the result." "In Scope" {

            orchestratorApi = container "Orchestrator API" "Accepts payment requests and network answers. Saves each one together with a work item in a single transaction, ignores duplicates, and serves the read-only operations pages." "ASP.NET Core" "App"

            paymentWorker = container "Payment Worker" "Picks up work items and moves each payment through its steps: screen, reserve, send, confirm, post, notify. Retries safely, times out silent networks, and releases holds on failure." ".NET Worker Service" "App"

            platformDb = container "Platform Database" "Stores payments and their state history, idempotency keys, the work item queue, and raw network messages." "Azure SQL Database" "Database"
        }

        # ---------- Relationships: people ----------
        viewer -> orchestratorApi "Views payments and funds using" "HTTPS"
        developer -> coreSim "Submits normal, duplicate, and failing payments with" "Command line"
        developer -> networkSim "Chooses accept, reject, delay, or silence using" "Command line"
        developer -> paymentWorker "Stops and restarts, to show recovery, on" "Command line"

        # ---------- Relationships: incoming ----------
        coreSim -> orchestratorApi "Submits payment requests to" "HTTPS/JSON"
        networkSim -> orchestratorApi "Sends payment answers to" "Webhooks/HTTPS"

        # ---------- Relationships: inside the platform ----------
        orchestratorApi -> platformDb "Saves payments, idempotency keys, and work items in one transaction" "SQL"
        paymentWorker -> platformDb "Picks up work items and updates payment state" "SQL"

        # ---------- Relationships: outgoing ----------
        paymentWorker -> screeningStub "Screens payments with" "HTTPS/JSON"
        paymentWorker -> ledger "Reserves funds, posts entries, and releases holds with" "HTTPS/JSON"
        paymentWorker -> networkSim "Sends payment messages to" "HTTPS (ISO 20022 pacs.008)"
        paymentWorker -> coreSim "Notifies payment results to" "Webhooks/HTTPS"
        orchestratorApi -> ledger "Reads available funds from" "HTTPS/JSON"
    }

    views {

        container platform "Containers" {
            include *
            autoLayout lr
            title "CorporateOne Payment Orchestration MVP - Containers"
            description "One API, one worker, one database, plus test tools that stand in for the outside world."
        }

        dynamic platform "HappyPath" "One payment goes through all steps successfully." {
            coreSim -> orchestratorApi "1. Submits payment (unique request ID)"
            orchestratorApi -> platformDb "2. Saves payment and work item together"
            paymentWorker -> platformDb "3. Picks up the work item"
            paymentWorker -> screeningStub "4. Screens the payment"
            paymentWorker -> ledger "5. Reserves funds (ID: payment + step)"
            paymentWorker -> networkSim "6. Sends the payment message"
            networkSim -> orchestratorApi "7. Answers: accepted"
            orchestratorApi -> platformDb "8. Saves the answer and a new work item"
            paymentWorker -> ledger "9. Posts the held funds"
            paymentWorker -> coreSim "10. Notifies: payment completed"
            viewer -> orchestratorApi "11. Sees the finished payment"
            autoLayout lr
        }

        dynamic platform "SilentNetwork" "The network never answers, so the platform releases the hold." {
            coreSim -> orchestratorApi "1. Submits payment"
            orchestratorApi -> platformDb "2. Saves payment and work item"
            paymentWorker -> platformDb "3. Picks up the work item"
            paymentWorker -> ledger "4. Reserves funds"
            paymentWorker -> networkSim "5. Sends the payment message"
            paymentWorker -> platformDb "6. Time limit passes, marks the payment timed out"
            paymentWorker -> ledger "7. Releases the hold"
            paymentWorker -> coreSim "8. Notifies: payment failed, funds released"
            autoLayout lr
        }

        dynamic platform "WorkerCrash" "The worker stops in the middle and resumes without repeating effects." {
            paymentWorker -> platformDb "1. Picks up the work item"
            paymentWorker -> ledger "2. Reserves funds"
            developer -> paymentWorker "3. Stops the worker on purpose, then restarts it"
            paymentWorker -> platformDb "4. Finds the unfinished work item and its state"
            paymentWorker -> ledger "5. Repeats the reserve call with the same ID, so nothing changes"
            paymentWorker -> networkSim "6. Continues and sends the payment message"
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
            element "Test Tool" {
                background #bbbbbb
                color #ffffff
                border dashed
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