terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.13.0"
    }
  }
}
provider "helm" {
  kubernetes {
    config_path = "${var.kubeconfig}"
  }
}
provider "kubectl" {
  config_path    = "${var.kubeconfig}"
}

locals {
  metrics_url = var.metrics_url != null ? var.metrics_url : "kube-prometheus-stack-prometheus-node-exporter.observability.svc:9100"
  tracing_url = var.tracing_url != null ? var.tracing_url : "tempo.observability.svc:3100"
  logging_url = var.logging_url != null ? var.logging_url : "loki.observability.svc:3100"
  path        = "${path.module}"
}



data "template_file" "collector_config_tpl" {
  template = "${file("${path.module}/collector-values.tpl")}"
  vars = {
    metrics_url = local.metrics_url
    tracing_url = local.tracing_url
    logging_url = local.logging_url
    url         = var.url
    
  }
}
resource "local_file" "collector_config" {
    content     = "${data.template_file.collector_config_tpl.rendered}"
    filename = "${path.module}/config/collector-values.yaml"
}
#https://artifacthub.io/packages/helm/opentelemetry-helm/opentelemetry-operator
resource "helm_release" "otel_operator" {
    name = "otel-operator"
    namespace = "otel-operator"
    create_namespace = true
    repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
    chart = "opentelemetry-operator"

    set {
    name  = "replicaCount"
    value = "2"
  }    
}

# data "local_file" "collector_config_yaml" {
#   template = "${file("${path.module}/collector-values.tpl")}"
#   vars = {
#     metrics_url = local.metrics_url
#     tracing_url = local.tracing_url
#     logging_url = local.logging_url
#     url         = var.url
    
#   }
# }
resource "helm_release" "otel_collector" {
    name = "otel-collector"
    namespace = "otel-collector"
    create_namespace = true
    repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
    chart = "opentelemetry-collector"
    timeout = 120
    values = [
        "${file("${local.path}/config/collector-values.yaml")}"
    ]
  
 depends_on = [resource.local_file.collector_config]
}

#https://github.com/jaegertracing/helm-charts/tree/main/charts/jaeger
resource "helm_release" "jaeger_operator" {
    name = "jaeger"
    namespace = "tracing"
    create_namespace = true
    repository = "https://jaegertracing.github.io/helm-charts"
    chart = "jaeger"

  set {
    name  = "provisionDataStore.cassandra"
    value = "false"
  } 
  set {
    name  = "provisionDataStore.elasticsearch"
    value = "true"
  }
  set {
    name  = "storage.type"
    value = "elasticsearch"
  }   
  set {
    name  = "query.ingress.enabled"
    value = "true"
  }   
  set {
    name  = "query.ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }
  set {
        name = "query.ingress.hosts[0]"
        value = "tracing.${var.url}"
  }    
  # set {
  #       name = "query.ingress.hosts[0].paths[0].path"
  #       value = "/"
  # }
  set {
        name = "query.ingress.tls[0].secretName"
        value = "tracing-tls"
  } 
  set {
        name = "query.ingress.tls[0].hosts[0]"
        value = "tracing.${var.url}"
  } 
  # set {
  #       name = "query.ingress.hosts[0].paths[0].port"
  #       value = "80"
  # }
  
}