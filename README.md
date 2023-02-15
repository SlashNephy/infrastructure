# k8s-manifests

[/slashnephy/k8s](https://scrapbox.io/slashnephy/k8s)

## Setup

- [1Password Connect Server & Operator](https://github.com/1Password/connect-helm-charts/tree/main/charts/connect)

```console
$ helm repo add 1password https://1password.github.io/connect-helm-charts
$ helm repo update
$ helm install connect \
    1password/connect \
    --set-file connect.credentials=1password-credentials.json \
    --set operator.create=true \
    --set operator.token.value=$OP_CONNECT_TOKEN \
    --set operator.autoRestart=true \
    -n 1password \
    --create-namespace
```

## Commands

- Create Argo CD resources

```console
$ kubectl kustomize --enable-helm system/argo-cd | kubectl apply -f -
```

- Generate bearer token for kubernetes-dashboard

```console
$ kubectl create token admin-user -n kubernetes-dashboard --duration=4294967296s
```

- Check Argo CD initial password

```console
$ kubectl get secret argocd-initial-admin-secret \
    -n argo-cd \
    -o jsonpath="{.data.password}" | base64 -d; echo
```
