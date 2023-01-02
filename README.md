# k8s-manifests

## Setup

- [1Password Connect Server & Operator](https://github.com/1Password/connect-helm-charts/tree/main/charts/connect)

```console
$ helm repo add 1password https://1password.github.io/connect-helm-charts
$ helm install connect \
    1password/connect \
    --set-file connect.credentials=1password-credentials.json \
    --set operator.create=true \
    --set operator.token.value=$OP_CONNECT_TOKEN \
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

- Generate bearer token for kubernetes-dashboard

```console
$ kubectl create token admin-user -n kubernetes-dashboard --duration=4294967296s
```
