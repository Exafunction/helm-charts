# exadeploy

<img src="../../images/banner.png" alt="Banner" width="1280"/>

A Helm chart for the ExaDeploy system by Exafunction.

![Version: 1.1.0](https://img.shields.io/badge/Version-1.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.10.0](https://img.shields.io/badge/AppVersion-0.10.0-informational?style=flat-square)

## Get Helm Repository Info

```console
helm repo add exafunction https://exafunction.github.io/helm-charts/
helm repo update
```

*See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation.*

## Install Chart

```console
helm install [RELEASE_NAME] exafunction/exadeploy
```

*See [Configuration](#configuration) section below.*

*See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation.*

## Uninstall Helm Chart

```console
helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

*See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation.*

## Upgrade Chart

```console
helm upgrade [RELEASE_NAME] exafunction/exadeploy
```

*See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation.*

## Configuration

This section covers the most common configuration options. To see all configuration options with detailed comments, see the [Values](#values) section, check out the [values.yaml](values.yaml) file, or use the CLI:

```console
helm show values exafunction/exadeploy
```

*See [helm show values](https://helm.sh/docs/helm/helm_show_values/) for command documentation.*

*See [Customizing the Chart Before Installing](https://helm.sh/docs/topics/charts/#customizing-the-chart-before-installing) for instructions on how to configure the chart.*

### Exafunction API Key (Required)
In order to install this Helm chart, you **must** specify a Kubernetes secret containing the Exafunction API key. This is used to identify the ExaDeploy system and should be provided by Exafunction. The secret must exist before installing the Helm chart and by default is expected to contain a key named `api_key` with the value being the API key.

Example values file:

```yaml
exafunction:
  apiKeySecret:
    name: exafunction-api-key
```

### ExaDeploy Component Images (Required)
In order to install this Helm chart, you **must** specify ExaDeploy component images. These should be provided by Exafunction and determine the specific version and build of the ExaDeploy components that will be deployed.

Example values file:

```yaml
scheduler:
  image: "foo.bar.com/scheduler:abcd_1234"
moduleRepository:
  image: "foo.bar.com/module_repository:abcd_1234"
runner:
  image: "foo.bar.com/runner:abcd_1234"
```

### Module Repository Persistent Backend
The module repository can be configured to use either a local backend on disk (default) or a remote backend backed by a Postgres database and cloud storage bucket (e.g. S3, GCS, etc.). The remote backend allows for persistence between module repository restarts and is recommended in production.

In order to configure a remote backend for the module repository, you must change the `moduleRepository.backend.type` to `remote`, configure the remote Postgres connection, set the `moduleRepository.backend.remote.dataBackend` to the cloud storage provider, and configure the appropriate cloud storage provider settings. Note that the Postgres database and cloud storage bucket must already exist before installing the Helm chart. Additionally, the access information for both must exist as Kubernetes secrets.

By default, the postgres password secret is expected to contain a key named `postgres_password` with the value being the password. The cloud storage secret format is provider-specific. For S3, the secret is by default expected to contain a key named `access_key` with the value being the access key ID and a key named `secret_key` with the value being the secret access key. For GCS, the secret is by default expected to contain a key named `gcp-credentials.json` with the value being the GCP JSON credentials file.

Example values file (AWS):

```yaml
moduleRepository:
  backend:
    type: "remote"
    postgres:
      host: "postgres.example.com"
      port: 5432
      database: "exadeploy"
      user: "exadeploy"
      passwordSecret:
        name: "postgres-password"
    dataBackend: "s3"
    s3:
      region: "us-east-1"
      bucket: "exadeploy"
      awsAccessKeySecret:
        name: "aws-access-key"
```

Example values file (GCP):

```yaml
moduleRepository:
  backend:
    type: "remote"
    postgres:
      host: "postgres.example.com"
      port: 5432
      database: "exadeploy"
      user: "exadeploy"
      passwordSecret:
        name: "postgres-password"
    dataBackend: "gcs"
    gcs:
      region: "us-east1"
      bucket: "exadeploy"
      gcpCredentialsSecret:
        name: "gcs-gcp-credentials"
```

### Kubernetes Scheduling
To manage scheduling of the ExaDeploy component pods on Kubernetes nodes, you can specify Kubernetes [NodeSelectors](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) and [Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) for each component type.

Note that runner pods will request GPU resources by default unless `runner.cpuOnly` is set to true (which causes all runners to only use CPU). If only some runners should run on CPU, clients should specify the CPU only setting at session creation time.

Example values file:

```yaml
scheduler:
  nodeSelector:
    foo: "bar"
  tolerations:
  - key: "foo"
    operator: "Equal"
    value: "bar"
    effect: "NoSchedule"
moduleRepository:
  nodeSelector:
    foo: "bar"
  tolerations:
  - key: "foo"
    operator: "Equal"
    value: "bar"
    effect: "NoSchedule"
runner:
  nodeSelector:
    foo: "bar"
  tolerations:
  - key: "foo"
    operator: "Equal"
    value: "bar"
    effect: "NoSchedule"
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| exafunction.annotations | object | `{}` | Annotations to add to deployments and runner pods. |
| exafunction.apiKeySecret.key | string | `"api_key"` | Key in <name> Kubernetes secret with Exafunction API key value. |
| exafunction.apiKeySecret.name | string | `nil` | Name of Kubernetes secret containing Exafunction API key. |
| exafunction.clusterDomain | string | `"cluster.local"` | Kubernetes cluster domain name used to construct fully qualified domain names for Exafunction services. |
| exafunction.suffix | string | `""` | Global suffix to apply to all Kubernetes objects. |
| moduleRepository.additionalConfig | string | `""` | Additional module repository config settings in yaml format. |
| moduleRepository.backend.local.localMetadataBaseDir | string | `"/tmp/exafunction/module_repository/metadata"` | Location to store metadata for the local metadata backend. |
| moduleRepository.backend.remote.dataBackend | string | `"s3"` | Module repository data backend type. Must be one of [s3] |
| moduleRepository.backend.remote.gcs.bucket | string | `nil` | Name of the GCS bucket used to store module repository objects. |
| moduleRepository.backend.remote.gcs.gcpCredentialsSecret.gcpCredentialsJsonKey | string | `"gcp-credentials.json"` | Key in <name> Kubernetes secret with GCP credentials JSON value. |
| moduleRepository.backend.remote.gcs.gcpCredentialsSecret.name | string | `nil` | Name of Kubernetes secret containing GCP credentials to access the GCS bucket. |
| moduleRepository.backend.remote.postgres.database | string | `nil` | Name of the Postgres database. |
| moduleRepository.backend.remote.postgres.host | string | `nil` | Host (address) of the Postgres instance. |
| moduleRepository.backend.remote.postgres.passwordSecret.key | string | `"postgres_password"` | Key in <name> Kubernetes secret with Postgres password value. |
| moduleRepository.backend.remote.postgres.passwordSecret.name | string | `nil` | Name of Kubernetes secret containing password to use when connecting to the Postgres instance. |
| moduleRepository.backend.remote.postgres.port | string | `nil` | Port of the Postgres instance. |
| moduleRepository.backend.remote.postgres.sslCertificateName | string | `nil` | If using SSL, contains the name of the .pem certificate file. |
| moduleRepository.backend.remote.postgres.sslConfigMapName | string | `nil` | If using SSL, contains the name of the config map containing the certificate file. |
| moduleRepository.backend.remote.postgres.user | string | `nil` | Username to use when connecting to the Postgres instance. |
| moduleRepository.backend.remote.s3.awsAccessKeySecret.accessKeyIdKey | string | `"access_key"` | Key in <name> Kubernetes secret with AWS access key ID value. |
| moduleRepository.backend.remote.s3.awsAccessKeySecret.name | string | `nil` | Name of Kubernetes secret containing AWS access credentials to access the S3 bucket. |
| moduleRepository.backend.remote.s3.awsAccessKeySecret.secretAccessKeyKey | string | `"secret_key"` | Key in <name> Kubernetes secret with AWS secret access key value. |
| moduleRepository.backend.remote.s3.bucket | string | `nil` | Name of the S3 bucket used to store module repository objects. |
| moduleRepository.backend.remote.s3.region | string | `nil` | AWS region of the S3 bucket (i.e. "us-west-1", etc.). |
| moduleRepository.backend.type | string | `"local"` | Module repository backend type. Must be one of [local, remote]. |
| moduleRepository.image | string | `nil` | Image path for the module repository. |
| moduleRepository.ingress.annotations | object | `{"nginx.ingress.kubernetes.io/backend-protocol":"GRPC"}` | Module repository ingress annotations. |
| moduleRepository.ingress.className | string | `"nginx"` | Module repository ingress class name. |
| moduleRepository.ingress.enabled | bool | `false` | Whether to enable module repository ingress. |
| moduleRepository.ingress.host | string | `nil` | Module repository ingress host. |
| moduleRepository.nodeSelector | object | `{}` | Module repository nodeSelectors. Should be a map from label names to label values. |
| moduleRepository.port | int | `50051` | Port to expose the module repository on. |
| moduleRepository.service.annotations | object | `{"cloud.google.com/load-balancer-type":"Internal","service.beta.kubernetes.io/aws-load-balancer-internal":"true","service.beta.kubernetes.io/azure-load-balancer-internal":"true"}` | Module repository service annotations. |
| moduleRepository.service.type | string | `"LoadBalancer"` | Module repository service type. |
| moduleRepository.serviceAccountName | string | `nil` | Optional specific serviceAccountName for the module repository. |
| moduleRepository.tolerations | list | `[]` | Module repository tolerations. Should be a list of objects with keys [key, operator, value (unnecessary when operator is "Exists"), effect]. |
| prometheus.port | int | `2112` | Controls the value of prometheus.io/port. |
| rbac.create | bool | `true` | Specifies whether RBAC resources should be created. |
| runner.additionalConfig | string | `""` | Additional scheduler config map settings in yaml format. |
| runner.cpuLimit | string | `nil` | Runner Kubernetes CPU limit. |
| runner.cpuOnly | bool | `false` | Whether runners should only run on CPU. |
| runner.createHeadlessService | bool | `false` | Whether to create a headless service to enable pod lookup by fully qualified pod hostname. |
| runner.image | string | `nil` | Image path for the runner. |
| runner.ingress.enabled | bool | `false` | Whether to enable runner ingress. |
| runner.ingress.host | string | `nil` | Runner ingress host. |
| runner.memoryLimit | string | `nil` | Runner Kubernetes memory limit. |
| runner.nodeSelector | object | `{}` | Runner nodeSelectors. Should be a map from label names to label values. |
| runner.port | int | `50100` | Port to expose runners on. |
| runner.serializeAll | bool | `false` | Whether to serialize all module execution. |
| runner.serviceAccountName | string | `nil` | Optional specific serviceAccountName for runners. |
| runner.tolerations | list | `[]` | Runner tolerations. Should be a list of objects with keys [key, operator, value (unnecessary when operator is "Exists"), effect]. |
| runner.useLoadBalancerServiceIp | bool | `false` | Whether to use per-runner load balancer service IPs. |
| runner.valueStorePort | int | `50101` | Port to expose value store on. |
| runner.valueStoreThreads | int | `4` | Number of threads for value store. |
| scheduler.additionalConfig | string | `""` | Additional scheduler config settings in yaml format. |
| scheduler.cpuLimit | string | `"2.5"` | Scheduler Kubernetes CPU limit. |
| scheduler.disableClientsKillingRunners | bool | `false` | Normally, the scheduler will delete runners which clients fail to connect to. This disables that behavior to allow for inspection of the failed runners. |
| scheduler.extraEnvs | list | `[]` | Extra environment variables for the scheduler. |
| scheduler.image | string | `nil` | Image path for the scheduler. |
| scheduler.ingress.annotations | object | `{"nginx.ingress.kubernetes.io/backend-protocol":"GRPC"}` | Scheduler ingress annotations. |
| scheduler.ingress.className | string | `"nginx"` | Scheduler ingress class name. |
| scheduler.ingress.enabled | bool | `false` | Whether to enable scheduler ingress. |
| scheduler.ingress.host | string | `nil` | Scheduler ingress host. |
| scheduler.maxRunners | string | `nil` | Maxmimum number of concurrent runners (default unbounded). |
| scheduler.minRunners | string | `nil` | Minimum number of concurrent runners (default 0). |
| scheduler.nodeSelector | object | `{}` | Scheduler nodeSelectors. Should be a map from label names to label values. |
| scheduler.placementGroupDeletionLagSeconds | int | `5` | Number of seconds to wait before deleting unused placement group from runners. |
| scheduler.port | int | `50050` | Port to expose the scheduler on. |
| scheduler.runnerCreationTimeoutSeconds | int | `600` | Number of seconds to wait for runner creation. |
| scheduler.runnerDeletionLagSeconds | int | `5` | Number of seconds to wait before deleting unused runner. |
| scheduler.service.annotations | object | `{"cloud.google.com/load-balancer-type":"Internal","service.beta.kubernetes.io/aws-load-balancer-internal":"true","service.beta.kubernetes.io/azure-load-balancer-internal":"true"}` | Scheduler service annotations. |
| scheduler.service.type | string | `"LoadBalancer"` | Scheduler service type. |
| scheduler.serviceAccountName | string | `nil` | Optional specific serviceAccountName for the scheduler. |
| scheduler.tolerations | list | `[]` | Scheduler tolerations. Should be a list of objects with keys [key, operator, value (unnecessary when operator is "Exists"), effect]. |
| serviceAccount.annotations | object | `{}` | ServiceAccount annotations. |
| serviceAccount.create | bool | `true` | Specifies whether a ServiceAccount should be created. |
| serviceAccount.name | string | `nil` | The name of the ServiceAccount to use. If not set and create is true, a name is generated automatically. |
