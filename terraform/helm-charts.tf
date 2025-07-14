resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.7.0"

  values = [file("helm-values/nginx-ingress-values.yaml")]

  timeout         = 600
  cleanup_on_fail = true
}
