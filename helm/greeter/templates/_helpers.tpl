{{/*
Expand the name of the release.
*/}}
{{- define "greeter.fullname" -}}
{{- printf "%s-greeter" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to all resources.
*/}}
{{- define "greeter.labels" -}}
app.kubernetes.io/name: greeter
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels — used by the Deployment selector and Service selector.
Must be stable across upgrades (no chart version here).
*/}}
{{- define "greeter.selectorLabels" -}}
app.kubernetes.io/name: greeter
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
