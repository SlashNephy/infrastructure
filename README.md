# k8s-manifests

## Setup

- [kubernetes-dashboard](https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard)

```console
$ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
$ helm install kubernetes-dashboard \
    kubernetes-dashboard/kubernetes-dashboard \
    -n kubernetes-dashboard \
    --create-namespace
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
