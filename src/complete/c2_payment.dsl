workspace "OneCredit Payment Orchestration - Containers" "Container view of the Payment Orchestration Platform." {

    model {

        # ---------- People ----------
        cuOps = person "Credit Union Payments Staff" "Track payments, returns, and exceptions for their own credit union."
        cuTreasury = person "Credit Union Treasury Officer" "Monitors the credit union's liquidity and settlement position."
        coOps = person "OneCredit Payment Operations" "Monitor payment flow across all member credit unions and resolve exceptions."

        # ---------- Other systems ----------
        cuCore = softwareSystem "Credit Union Core Processor" "System of record for the credit union's member accounts and transactions." "External"
        coLedger = softwareSystem "OneCredit Settlement Accounts" "OneCredit's ledger of member credit union accounts and settlement positions." "Internal"
        screening = softwareSystem "Sanctions and Fraud Screening" "Third-party service that checks payments against sanctions lists and fraud signals." "External"
        fedServices = softwareSystem "Federal Reserve Payment Services" "Fed-operated services, including FedNow, that move and settle money." "External"
        rtpNetwork = softwareSystem "RTP Network" "Real-time payment network operated by The Clearing House." "External"

        # ---------- The system we are zooming into ----------
        platform = softwareSystem "Payment Orchestration Platform" "Receives payment requests, validates and routes them to the right network, and monitors liquidity in real time." "In Scope" {

            # Entry points
            apiGateway = container "API Gateway" "Single secured entry point: authentication, rate limiting, and routing for credit union cores and the portal." "Azure API Management" "Gateway"
            portal = container "Operations Portal" "Lets credit union and OneCredit staff view payments, positions, and alerts. Users only see their own credit union's data, except OneCredit staff." "Blazor WebAssembly" "WebApp"

            # Core logic
            orchestrator = container "Payment Orchestrator" "Runs each payment from start to finish: checks for duplicates, screens, reserves funds, sends, and records the result." "ASP.NET Core"
            isoService = container "ISO 20022 Message Service" "Builds, validates, and reads ISO 20022 messages so no other part has to know the formats." ".NET Worker Service"
            liquidityMonitor = container "Liquidity Monitor" "Tracks each credit union's settlement position, compares it to thresholds, and raises alerts." "ASP.NET Core"

            # Connectors to the outside world
            fedConnector = container "FedNow Connector" "Handles the connection, security, and timing rules of FedNow. Sends payments and receives responses." ".NET Worker Service" "Connector"
            rtpConnector = container "RTP Connector" "Handles the connection, security, and timing rules of RTP. Sends payments and receives responses." ".NET Worker Service" "Connector"
            notifier = container "Core Notification Service" "Tells credit union cores about payment results, returns, and incoming credits. Retries until delivered." "Azure Functions" "Connector"

            # Shared infrastructure
            serviceBus = container "Message Bus" "Carries payment events, network responses, and alerts between containers." "Azure Service Bus" "Queue"
            database = container "Platform Database" "Stores payment state, idempotency keys, credit union configuration, thresholds, alert history, and audit records." "Azure SQL Database" "Database"
            keyVault = container "Key Vault" "Stores network certificates, private keys, and secrets." "Azure Key Vault" "Vault"
        }

        # ---------- Relationships: people ----------
        cuOps -> portal "Tracks payments and resolves exceptions using" "HTTPS"
        cuTreasury -> portal "Monitors liquidity and settlement position using" "HTTPS"
        coOps -> portal "Monitors all payment activity using" "HTTPS"

        # ---------- Relationships: entry points ----------
        portal -> apiGateway "Requests payment and liquidity data from" "HTTPS/JSON"
        cuCore -> apiGateway "Submits payment requests to" "HTTPS/JSON"
        apiGateway -> orchestrator "Forwards payment requests to" "HTTPS"
        apiGateway -> liquidityMonitor "Forwards liquidity queries to" "HTTPS"

        # ---------- Relationships: payment flow ----------
        orchestrator -> database "Reads and writes payment state and idempotency keys" "SQL"
        orchestrator -> screening "Screens payments with" "HTTPS/JSON"
        orchestrator -> coLedger "Checks funds and posts settlement entries to" "HTTPS/JSON"
        orchestrator -> isoService "Asks to build and read ISO 20022 messages" "gRPC"
        orchestrator -> fedConnector "Sends FedNow payments to" "gRPC"
        orchestrator -> rtpConnector "Sends RTP payments to" "gRPC"
        orchestrator -> serviceBus "Publishes payment status events to" "AMQP"
        serviceBus -> orchestrator "Delivers network responses and incoming payments to" "AMQP"

        # ---------- Relationships: networks ----------
        fedConnector -> fedServices "Sends payments to" "ISO 20022 / mTLS"
        fedServices -> fedConnector "Sends confirmations and incoming payments to" "ISO 20022 / mTLS"
        rtpConnector -> rtpNetwork "Sends payments to" "ISO 20022 / mTLS"
        rtpNetwork -> rtpConnector "Sends confirmations and incoming payments to" "ISO 20022 / mTLS"
        fedConnector -> serviceBus "Publishes network responses to" "AMQP"
        rtpConnector -> serviceBus "Publishes network responses to" "AMQP"
        fedConnector -> keyVault "Gets certificates and keys from" "HTTPS"
        rtpConnector -> keyVault "Gets certificates and keys from" "HTTPS"

        # ---------- Relationships: notifications ----------
        serviceBus -> notifier "Delivers status events to" "AMQP"
        notifier -> cuCore "Notifies of payment results, returns, and incoming credits" "Webhooks/HTTPS"
        notifier -> database "Records delivery attempts in" "SQL"

        # ---------- Relationships: liquidity ----------
        liquidityMonitor -> coLedger "Reads settlement positions from" "HTTPS/JSON"
        liquidityMonitor -> database "Reads thresholds and stores alert history in" "SQL"
        liquidityMonitor -> serviceBus "Publishes liquidity alerts to" "AMQP"
        serviceBus -> liquidityMonitor "Delivers settlement events to" "AMQP"
    }

    views {

        container platform "Containers" {
            include *
            autoLayout lr
            title "OneCredit Payment Orchestration - Containers"
            description "The main building blocks of the platform and how they connect to people and outside systems."
        }

        dynamic platform "OutboundPayment" "How one outgoing FedNow payment travels through the platform." {
            cuCore -> apiGateway "1. Submits payment request"
            apiGateway -> orchestrator "2. Forwards request"
            orchestrator -> database "3. Checks for duplicate, records payment"
            orchestrator -> screening "4. Screens payment"
            orchestrator -> coLedger "5. Checks and reserves funds"
            orchestrator -> isoService "6. Asks for ISO 20022 message"
            orchestrator -> fedConnector "7. Sends payment"
            fedConnector -> fedServices "8. Sends message to network"
            fedServices -> fedConnector "9. Returns confirmation"
            fedConnector -> serviceBus "10. Publishes network response"
            serviceBus -> orchestrator "11. Delivers response"
            orchestrator -> coLedger "12. Posts settlement entries"
            orchestrator -> serviceBus "13. Publishes final status"
            serviceBus -> notifier "14. Delivers status event"
            notifier -> cuCore "15. Notifies credit union core"
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
            element "Connector" {
                background #85bbf0
                color #000000
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
            element "Vault" {
                background #5c5c5c
                color #ffffff
            }
            relationship "Relationship" {
                color #707070
            }
        }
    }
}