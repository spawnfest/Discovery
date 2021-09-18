# Notes during development

## minikube

- `minikube start --driver=docker`
- `kubectl config use-context minikube`
- `docker login`
- `k create deployment watchex --image madclaws/watchex:0.1.1_dev`


- `kubectl expose deployment watchex --type=NodePort --port=4000`
- `k get services`

- `minikube service --url watchex-a -n games`

- `minikube addons enable ingress `

```
alias Discovery.Engine.Builder

{_, {_, bid}} = Builder.start_link

Process.exit(bid, :kill)
```