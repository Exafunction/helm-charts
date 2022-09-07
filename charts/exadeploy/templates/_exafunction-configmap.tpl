{{- define "exadeploy.configmap" -}}
module_repository {
  listen_port: {{ .Values.moduleRepository.port }}
  {{- if .Values.moduleRepository.ingress.enabled }}
  hostname: {{ required "A valid moduleRepository.ingress.host is required" .Values.moduleRepository.ingress.host | quote }}
  external_port: 80
  internal_hostname: {{ include "exadeploy.moduleRepositoryName" . | quote }}
  {{- else }}
  hostname: {{ include "exadeploy.moduleRepositoryName" . | quote }}
  {{- end }}
  cache_dir: "/tmp/module_repository/cache"
  max_cache_size_in_gb: 50
  {{- if eq .Values.moduleRepository.backend.type "remote" }}
  postgres_metadata_backend {}
  {{- if eq .Values.moduleRepository.backend.remote.dataBackend "s3" }}
  s3_data_backend {
    region: {{ required "A valid moduleRepository.backend.remote.s3.region is required." .Values.moduleRepository.backend.remote.s3.region | quote }}
    bucket: {{ required "A valid moduleRepository.backend.remote.s3.bucket is required." .Values.moduleRepository.backend.remote.s3.bucket | quote }}
    base_dir: "/module_repository"
  }
  {{- else }}
  {{ fail "Invalid .Values.moduleRepository.backend.remote.dataBackend" }}
  {{- end }}
  {{- else if eq .Values.moduleRepository.backend.type "local" }}
  local_data_backend {}
  local_metadata_backend {
    base_dir: {{ required "A valid moduleRepository.backend.local.localMetadataBaseDir is required." .Values.moduleRepository.backend.local.localMetadataBaseDir | quote }}
  }
  {{- else }}
  {{ fail "Invalid .Values.moduleRepository.backend.type" }}
  {{- end }}
  {{- .Values.moduleRepository.additionalConfig | nindent 2 }}
}

scheduler {
  hostname: "scheduler-service{{- include "exadeploy.suffix" . }}"
  listen_port: {{ .Values.scheduler.port }}
  session_reinitialization_first_heartbeat_timeout_seconds: 60
  placement_group_deletion_lag_seconds: {{ .Values.scheduler.placementGroupDeletionLagSeconds }}
  log_invocation_time: true
  {{- if .Values.scheduler.minRunners }}
  min_runners: {{ .Values.scheduler.minRunners }}
  {{- end }}
  {{- if .Values.scheduler.maxRunners }}
  max_runners: {{ .Values.scheduler.maxRunners }}
  {{- end }}
  runner_creation_timeout_seconds: {{ .Values.scheduler.runnerCreationTimeoutSeconds }}
  max_consecutive_runner_creation_failures: 5
  runner_create_failure_cooldown_seconds: 100
  runner_service_creation_timeout_seconds: 600
  runner_deletion_lag_seconds: {{ .Values.scheduler.runnerDeletionLagSeconds }}
  load_balancing_enabled: true
  autoscaling_enabled: true
  autoscaling_config {}
  use_runner_image_from_module: true
  {{- if .Values.scheduler.disableClientsKillingRunners }}
  disable_clients_killing_runners: true
  {{- end }}
  {{- .Values.scheduler.additionalConfig | nindent 2 }}
}

runner {
  {{- if .Values.runner.cpuOnly }}
  cpu_only: true
  {{- end }}
  kubernetes_launch_backend {
    docker_image: {{ required "A valid runner.image is required." .Values.runner.image | quote }},
    runner_port: {{ .Values.runner.port }}
    value_store_port: {{ .Values.runner.valueStorePort }}
    namespace: {{ .Release.Namespace | quote }}
    {{- if .Values.runner.memoryLimit }}
    memory_limit: {{ .Values.runner.memoryLimit | quote }}
    {{- end }}
    {{- if .Values.runner.cpuLimit }}
    cpu_limit: {{ .Values.runner.cpuLimit | quote }}
    {{- end }}
    {{- if .Values.exafunction.annotations }}
    {{- include "exadeploy.pbtxt" (dict "name" "pod_annotations" "values" .Values.exafunction.annotations) | indent 4 }}
    {{- end }}
    {{- if .Values.runner.nodeSelector }}
    {{- include "exadeploy.pbtxt" (dict "name" "node_selectors" "values" .Values.runner.nodeSelector) | indent 4 }}
    {{- end }}
    {{- range .Values.runner.tolerations }}
    tolerations {
      key: {{ required "A valid .key is required" .key | quote }}
      operator: {{ required "A valid .operator is required" .operator | quote }}
      {{- if eq .operator "Equal" }}
      value: {{ required "A valid .value is required" .value | quote }}
      {{- end }}
      effect: {{ required "A valid .effect is required" .effect | quote }}
    }
    {{- end }}
    runner_pod_app_label_value: "exafunction-runner{{- include "exadeploy.suffix" . }}"
    runner_service_app_label_value: "exafunction-runner-service{{- include "exadeploy.suffix" . }}"
    {{- if .Values.exafunction.suffix }}
    runner_pod_name_suffix: {{ .Values.exafunction.suffix | quote }}
    {{- end }}
    {{- if .Values.runner.useLoadBalancerServiceIp }}
    use_load_balancer_service_ip: true
    {{- end }}
    {{- if .Values.runner.createHeadlessService }}
    create_headless_service: true
    subdomain: "headless{{- include "exadeploy.suffix" . }}"
    {{- end }}
    service_account_name: {{ .Values.runner.serviceAccountName | default (include "exadeploy.serviceAccountName" .) | quote }}
    {{- if .Values.runner.ingress.enabled }}
    create_ingress_per_runner: true
    external_service_hostname: {{ required "A valid runner.ingress.host is required" .Values.runner.ingress.host | quote }}
    {{- else }}
    external_service_hostname: {{ .Values.runner.ingress.host | default "" | quote }}
    {{- end }}
    {{- if and (eq .Values.moduleRepository.backend.type "remote") (eq .Values.moduleRepository.backend.remote.dataBackend "s3") }}
    aws_credentials {
      access_key_id_secret_name: {{ .Values.moduleRepository.backend.remote.s3.awsAccessKeySecret.name | quote }}
      access_key_id_secret_key: {{ .Values.moduleRepository.backend.remote.s3.awsAccessKeySecret.accessKeyIdKey | quote }}
      secret_access_key_secret_name: {{ .Values.moduleRepository.backend.remote.s3.awsAccessKeySecret.name | quote }}
      secret_access_key_secret_key: {{ .Values.moduleRepository.backend.remote.s3.awsAccessKeySecret.secretAccessKeyKey | quote }}
    }
    {{- end }}
  }
  value_store_threads: {{ .Values.runner.valueStoreThreads }}
  {{- if .Values.runner.serializeAll }}
  serialize_all: true
  {{- end }}
  {{- if eq .Values.moduleRepository.backend.type "remote" }}
  load_from_blob_storage: true
  {{- end }}
  {{- .Values.runner.additionalConfig | nindent 2 }}
}

metrics_export_port: {{ .Values.prometheus.port }}

{{- if eq .Values.moduleRepository.backend.type "remote" }}
postgres_name: {{ required "A valid moduleRepository.backend.remote.postgres.database is required." .Values.moduleRepository.backend.remote.postgres.database | quote }}
postgres_host: {{ required "A valid moduleRepository.backend.remote.postgres.host is required." .Values.moduleRepository.backend.remote.postgres.host | quote }}
postgres_user: {{ required "A valid moduleRepository.backend.remote.postgres.user is required." .Values.moduleRepository.backend.remote.postgres.user | quote }}
postgres_port: {{ required "A valid moduleRepository.backend.remote.postgres.port is required." .Values.moduleRepository.backend.remote.postgres.port }}
{{- if .Values.moduleRepository.backend.remote.postgres.sslCertificateName }}
postgres_ssl_cert_path: "/etc/ssl-cert/{{ .Values.moduleRepository.backend.remote.postgres.sslCertificateName }}"
{{- end }}
{{- end }}

billing_addr: "https://billing.exafunction.com"

kubernetes_secret_dir: "/etc/system_secrets"
{{- end }}
