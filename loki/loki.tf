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
  tracing_url = var.tracing_url != null ? var.tracing_url : "loki.obervability.svc:3100"
  logging_url = var.logging_url != null ? var.logging_url : "loki.obervability.svc:3100"
  path        = "${path.module}"
}

resource "null_resource" "grafana-loki" {
  triggers  =  { always_run = "${timestamp()}" }
  provisioner "local-exec" {
    command = "helm --kubeconfig ${var.kubeconfig} repo add grafana https://grafana.github.io/helm-charts"
  }
  
}
#https://artifacthub.io/packages/helm/grafana/loki-distributed
resource "helm_release" "loki" {
  name       = "logging"
  repository = "grafana"
  chart      = "loki-distributed"
  #version    = "0.16.2"
  namespace  = "observability"
  create_namespace = true
  depends_on = [
    null_resource.grafana-loki
  ]
}