terraform {
  backend "local" {
    
  }
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
provider "kubernetes" {
  config_path    = "${var.kubeconfig}"
  
}
provider "kubectl" {
  config_path    = "${var.kubeconfig}"
  
}

# module "cert_manager" {
#   source        = "terraform-iaac/cert-manager/kubernetes"
  
#   cluster_issuer_email                   = "andrepassos.alp@gmail.com"
# #   cluster_issuer_name                    = "cert-manager-global"
# #   cluster_issuer_private_key_secret_name = "cert-manager-private-key"
#}
module "otel" {
    source = "./opentelemetry"
    kubeconfig = var.kubeconfig
    metrics_url = var.metrics_url
    tracing_url = var.tracing_url
    logging_url = var.logging_url
    url         = var.url

}
module "tempo" {
    source = "./tempo"
    kubeconfig = var.kubeconfig
    metrics_url = var.metrics_url
    tracing_url = var.tracing_url
    logging_url = var.logging_url
    url         = var.url

}

module "loki" {
    source = "./loki"
    kubeconfig = var.kubeconfig
    metrics_url = var.metrics_url
    tracing_url = var.tracing_url
    logging_url = var.logging_url
    url         = var.url

}