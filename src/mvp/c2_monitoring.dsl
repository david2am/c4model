// c2_monitoring.dsl — Monitoring and Alerting Platform relationships fragment
// Included into workspace.dsl. No workspace{} wrapper here.
// Containers are declared in c1.dsl inside 'monitoring'.

// ---------- Relationships: inbound from all platforms ----------
apim -> metricsCollector "Emits API request metrics (rate, latency, error count) to" "Prometheus remote write / HTTPS"
orchestratorApi -> metricsCollector "Emits payment creation metrics, idempotency hit rate to" "Prometheus remote write / HTTPS"
paymentWorker -> metricsCollector "Emits worker health, work item processing time, dead-letter count, network timeout count to" "Prometheus remote write / HTTPS"
isoService -> metricsCollector "Emits message parsing success/failure metrics to" "Prometheus remote write / HTTPS"

ledgerService -> metricsCollector "Emits hold/post/release operation metrics, overdraft rejection count, balance query latency to" "Prometheus remote write / HTTPS"
integrityJob -> metricsCollector "Emits integrity check pass/fail status, discrepancy count to" "Prometheus remote write / HTTPS"
cutoffScheduler -> metricsCollector "Emits business day cut-off event timestamps to" "Prometheus remote write / HTTPS"

collector -> metricsCollector "Emits data collection job completion time, API polling latency to" "Prometheus remote write / HTTPS"
reconEngine -> metricsCollector "Emits reconciliation break count, match rate to" "Prometheus remote write / HTTPS"
reportGenerator -> metricsCollector "Emits report generation success/failure, delivery metrics to" "Prometheus remote write / HTTPS"
accountingExporter -> metricsCollector "Emits GL export success/failure, retry count to" "Prometheus remote write / HTTPS"

// ---------- Relationships: log aggregation ----------
apim -> logAggregator "Sends structured logs (request traces, auth failures) to" "HTTPS/JSON"
orchestratorApi -> logAggregator "Sends structured logs (payment state transitions, duplicate detection) to" "HTTPS/JSON"
paymentWorker -> logAggregator "Sends structured logs (work item lifecycle, network responses, dead-letter writes) to" "HTTPS/JSON"
isoService -> logAggregator "Sends structured logs (message validation errors) to" "HTTPS/JSON"

ledgerService -> logAggregator "Sends structured logs (entry posts, overdraft rejections, idempotency hits) to" "HTTPS/JSON"
integrityJob -> logAggregator "Sends structured logs (integrity check results, discrepancies found) to" "HTTPS/JSON"
cutoffScheduler -> logAggregator "Sends structured logs (business day transitions) to" "HTTPS/JSON"

portal -> logAggregator "Sends structured logs (user actions, correction proposals) to" "HTTPS/JSON"
api -> logAggregator "Sends structured logs (two-person rule validations, approvals) to" "HTTPS/JSON"
collector -> logAggregator "Sends structured logs (data collection runs, download failures) to" "HTTPS/JSON"
reconEngine -> logAggregator "Sends structured logs (recon runs, break details) to" "HTTPS/JSON"

// ---------- Relationships: distributed tracing ----------
apim -> traceCollector "Sends trace spans for end-to-end request flows to" "OpenTelemetry / HTTPS"
orchestratorApi -> traceCollector "Sends trace spans (payment submission, database writes) to" "OpenTelemetry / HTTPS"
paymentWorker -> traceCollector "Sends trace spans (work item processing, network calls, settlement calls) to" "OpenTelemetry / HTTPS"
isoService -> traceCollector "Sends trace spans (message build/parse operations) to" "OpenTelemetry / HTTPS"

ledgerService -> traceCollector "Sends trace spans (hold/post/release operations) to" "OpenTelemetry / HTTPS"
integrityJob -> traceCollector "Sends trace spans (integrity check runs) to" "OpenTelemetry / HTTPS"

api -> traceCollector "Sends trace spans (correction submissions, ledger calls) to" "OpenTelemetry / HTTPS"
collector -> traceCollector "Sends trace spans (data collection runs, downstream API calls) to" "OpenTelemetry / HTTPS"
reconEngine -> traceCollector "Sends trace spans (reconciliation runs) to" "OpenTelemetry / HTTPS"

// ---------- Relationships: inside the monitoring platform ----------
metricsCollector -> monitoringDb "Writes time-series metrics to" "SQL / Prometheus TSDB"
logAggregator -> monitoringDb "Writes log index and structured log data to" "SQL / Elasticsearch"
traceCollector -> monitoringDb "Writes assembled trace spans to" "SQL / Jaeger storage"

alertManager -> metricsCollector "Queries metrics for alert rule evaluation" "PromQL / HTTPS"
alertManager -> logAggregator "Queries logs for alert rule evaluation" "Kusto / HTTPS"
alertManager -> traceCollector "Queries traces for anomaly detection" "HTTPS"

dashboardService -> metricsCollector "Queries time-series metrics for dashboard visualization" "PromQL / HTTPS"
dashboardService -> logAggregator "Queries logs for dashboard panels" "Kusto / HTTPS"
dashboardService -> traceCollector "Queries traces for request flow visualization" "HTTPS"

// ---------- Relationships: alert routing ----------
alertManager -> coOps "Notifies of worker failures, dead-letter growth, network timeouts, integrity check failures via" "Email / Slack / PagerDuty"
alertManager -> coFinance "Notifies of reconciliation break count threshold exceeded via" "Email / Slack"

// ---------- Relationships: operations staff ----------
coOps -> dashboardService "Views real-time operational metrics and traces using" "HTTPS"
coFinance -> dashboardService "Views reconciliation metrics and trends using" "HTTPS"
cuOps -> dashboardService "Views payment flow metrics for their own credit union using" "HTTPS"
cuTreasury -> dashboardService "Views settlement position trends and available funds charts using" "HTTPS"

// ---------- Relationships: authentication ----------
dashboardService -> identity "Validates staff tokens with" "OpenID Connect"
