# Argo Rollouts (Optional)

This project supports **progressive delivery** using **Argo Rollouts** when:
- `progressiveDelivery.enabled=true` in the Helm values.

## Install Argo Rollouts controller
```bash
kubectl create namespace argo-rollouts || true
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

## (Optional) Install kubectl plugin
```bash
# macOS (brew)
brew install argoproj/tap/kubectl-argo-rollouts

# Linux (example)
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
```

## Deploy using canary strategy
```bash
helm upgrade --install demo-api ./helm/demo-api -n demo --create-namespace   --set image.repository=<ECR_REPO_URL>   --set image.tag=<TAG>   --set progressiveDelivery.enabled=true   --set ingress.enabled=true
```

## Watch rollout
```bash
kubectl argo rollouts -n demo get rollout demo-api
kubectl argo rollouts -n demo watch rollout demo-api
```
