resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.2.1"
  set = [
    {
      name  = "server.insecure"
      value = "true"
    },
    {
      name  = "server.ingress.ingressClassName"
      value = "alb"
    },
    {
      name  = "server.ingress.enabled"
      value = "true"
    },
    {
      name  = "server.metrics.enabled"
      value = "true"
    },
    {
      name  = "server.metrics.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "server.metrics.serviceMonitor.additionalLabels.release"
      value = "kube-prometheus-stack"
    },
    {
        name = "controller.metrics.enabled"
        value = "true"
    },
    {
        name = "controller.metrics.serviceMonitor.enabled"
        value = "true"
    },
    {
        name  = "controller.metrics.serviceMonitor.additionalLabels.release"
        value = "kube-prometheus-stack"
    },
    {
        name = "repoServer.metrics.enabled"
        value = "true"
    },
    {
        name = "repoServer.metrics.serviceMonitor.enabled"
        value = "true"
    },
    {
        name  = "repoServer.metrics.serviceMonitor.additionalLabels.release"
        value = "kube-prometheus-stack"
    },
    {
        name = "applicationSet.metrics.enabled"
        value = "true"
    },
    {
        name = "applicationSet.metrics.serviceMonitor.enabled"
        value = "true"
    },
    {
        name  = "applicationSet.metrics.serviceMonitor.additionalLabels.release"
        value = "kube-prometheus-stack"
    },
    {
        name = "notificationsController.metrics.enabled"
        value = "true"
    },
    {
        name = "notificationsController.metrics.serviceMonitor.enabled"
        value = "true"
    },
    {
        name  = "notificationsController.metrics.serviceMonitor.additionalLabels.release"
        value = "kube-prometheus-stack"
    },
    {
        name = "redis.metrics.enabled"
        value = "true"
    },
    {
        name = "redis.metrics.serviceMonitor.enabled"
        value = "true"
    },
    {
        name  = "redis.metrics.serviceMonitor.additionalLabels.release"
        value = "kube-prometheus-stack"
    },
    {
        name = "dex.metrics.enabled"
        value = "true"
    },
    {
        name = "dex.metrics.serviceMonitor.enabled"
        value = "true"
    },
    {
        name  = "dex.metrics.serviceMonitor.additionalLabels.release"
        value = "kube-prometheus-stack"
    },
    {
        name = "server.ingress.annotations"
        value = <<EOT
          kubernetes.io/ingress.class: alb
          alb.ingress.kubernetes.io/scheme: internet-facing
          alb.ingress.kubernetes.io/target-type: ip
          alb.ingress.kubernetes.io/backend-protocol: HTTP
          EOT
    }
  ]
}

