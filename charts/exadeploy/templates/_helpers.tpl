{{/*
Expand the name of the chart.
*/}}
{{- define "exadeploy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "exadeploy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "exadeploy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "exadeploy.labels" -}}
helm.sh/chart: {{ include "exadeploy.chart" . }}
{{ include "exadeploy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "exadeploy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "exadeploy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Prepend a "-" to non-empty suffixes.
*/}}
{{- define "exadeploy.suffix" -}}
{{- if ne .Values.exafunction.suffix "" -}}
{{- printf "-%s" .Values.exafunction.suffix -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "exadeploy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "exadeploy.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Fully qualified name of the module repository.
*/}}
{{- define "exadeploy.moduleRepositoryName" -}}
module-repository-service{{- include "exadeploy.suffix" . }}
{{- if .Values.exafunction.clusterDomain -}}
.{{ .Release.Namespace }}.svc.{{ .Values.exafunction.clusterDomain }}
{{- end -}}
{{- end -}}

{{/*
Convert YAML key/values to a pbtxt map.
*/}}
{{- define "exadeploy.pbtxt" -}}
{{- $name := .name -}}
{{- range $k, $v := .values }}
{{ $name }} {
  key: {{ $k | quote }}
  value: {{ $v | quote }}
}
{{- end }}
{{- end -}}
