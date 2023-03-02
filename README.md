# infrastructure

[/slashnephy/k8s](https://scrapbox.io/slashnephy/k8s)

## Setup

```console
$ kubectl kustomize --enable-helm k8s/init | kubectl apply -f -
```

## Commands

- Generate bearer token for kubernetes-dashboard

```console
$ kubectl create token admin-user -n kubernetes-dashboard --duration=4294967296s
```

- Obtain Argo CD initial password

```console
$ kubectl get secret argocd-initial-admin-secret \
    -n argo-cd \
    -o jsonpath="{.data.password}" | base64 -d; echo
```

- Format / Lint manifest files

```console
$ yarn format
$ yarn lint
```
