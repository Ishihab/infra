resource "helm_release" "argo_cd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "10.2.1"
  namespace = "argocd"
  create_namespace = true
  values = [
    file("${path.module}/argocd_values.yaml")
  ]
  
}