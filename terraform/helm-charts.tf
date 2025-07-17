# # resource "helm_release" "nginx_ingress" {
# #   name             = "nginx-ingress"
# #   repository       = "https://kubernetes.github.io/ingress-nginx"
# #   chart            = "ingress-nginx"
# #   namespace        = "ingress-nginx"
# #   create_namespace = true


# #   timeout         = 600
# #   cleanup_on_fail = true
# # }

resource "helm_release" "cert_manager" {
  name             = "certmanager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.13.3"
  namespace        = "cert-manager"
  create_namespace = true

  values = [file("helm-values/cert-manager-values.yml")]
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = "default"

  values = [file("helm-values/externaldns-values.yml")]
}



resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  values           = [file("helm-values/argocd-values.yml")]
}



