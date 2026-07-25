resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = file("${path.module}/root-app.yaml")
  depends_on = [helm_release.argo_cd]
}


