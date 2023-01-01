# k8s-manifests

## Setup

- [kubernetes-dashboard](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard)

```console
$ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
$ helm install kubernetes-dashboard \
    kubernetes-dashboard/kubernetes-dashboard \
    -n kubernetes-dashboard \
    --create-namespace
$ kubectl create token admin-user -n kubernetes-dashboard --duration=4294967296s
```

- [1Password Connect Server & Operator](https://github.com/1Password/connect-helm-charts/tree/main/charts/connect)

```console
$ helm repo add 1password https://1password.github.io/connect-helm-charts
$ helm install connect \
    1password/connect \
    --set-file connect.credentials=1password-credentials.json \
    --set operator.create=true \
    --set operator.token.value=$OPERATOR_TOKEN \
    --set operator.autoRestart=true \
    -n 1password \
    --create-namespace
```

- [cert-manager](https://cert-manager.io/docs/installation/helm/)

```console
$ helm repo add jetstack https://charts.jetstack.io
$ helm install \
  cert-manager jetstack/cert-manager \
  --set installCRDs=true \
  -n traefik \
  --create-namespace
```

- [traefik](https://doc.traefik.io/traefik/getting-started/install-traefik/#use-the-helm-chart)

```console
$ helm repo add traefik https://helm.traefik.io/traefik
$ helm install traefik \
    traefik/traefik \
    -f system/traefik/values.yaml \
    -n traefik \
    --create-namespace
# alter editing values.yaml
$ helm upgrade traefik \
    traefik/traefik \
    -f system/traefik/values.yaml \
    -n traefik
```
