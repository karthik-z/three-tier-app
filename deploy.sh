#!/usr/bin/env bash
# ============================================================
# deploy.sh  –  Full Three-Tier Deploy on Minikube
# Usage:
#   ./deploy.sh deploy    – build images + apply all manifests
#   ./deploy.sh status    – show all running resources
#   ./deploy.sh teardown  – delete everything
# ============================================================
set -euo pipefail

NAMESPACE="three-tier"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()  { echo -e "\n\033[1;34m▶ $*\033[0m"; }
ok()    { echo -e "\033[1;32m  ✅ $*\033[0m"; }
warn()  { echo -e "\033[1;33m  ⚠️  $*\033[0m"; }

deploy() {
  # ── 1. Point Docker at Minikube ──────────────────────────
  info "STEP 1 · Pointing Docker at Minikube's daemon..."
  eval $(minikube docker-env)
  ok "Docker is now using Minikube's internal registry"

  # ── 2. Build images ──────────────────────────────────────
  info "STEP 2 · Building Spring Boot backend image..."
  docker build -t springboot-backend:latest "$DIR/backend"
  ok "springboot-backend:latest built"

  info "STEP 3 · Building Frontend image..."
  docker build -t frontend-ui:latest "$DIR/frontend"
  ok "frontend-ui:latest built"

  # ── 3. Apply Kubernetes manifests ────────────────────────
  info "STEP 4 · Creating namespace..."
  kubectl apply -f "$DIR/k8s/namespace.yaml"

  info "STEP 5 · Deploying MySQL (Secret → PV → ConfigMap → StatefulSet)..."
  kubectl apply -f "$DIR/k8s/mysql-secret.yaml"
  kubectl apply -f "$DIR/k8s/mysql-pv.yaml"
  kubectl apply -f "$DIR/k8s/mysql-configmap.yaml"
  kubectl apply -f "$DIR/k8s/mysql-statefulset.yaml"

  info "STEP 6 · Waiting for MySQL to be Ready (up to 3 min)..."
  kubectl rollout status statefulset/mysql -n "$NAMESPACE" --timeout=180s
  ok "MySQL StatefulSet is Ready"

  info "STEP 7 · Deploying Spring Boot Backend..."
  kubectl apply -f "$DIR/k8s/backend-deployment.yaml"
  kubectl rollout status deployment/backend -n "$NAMESPACE" --timeout=180s
  ok "Backend is Ready"

  info "STEP 8 · Deploying Frontend..."
  kubectl apply -f "$DIR/k8s/frontend-deployment.yaml"
  kubectl rollout status deployment/frontend -n "$NAMESPACE" --timeout=60s
  ok "Frontend is Ready"

  # ── 4. Print access URLs ─────────────────────────────────
  MINIKUBE_IP=$(minikube ip)
  echo ""
  echo "=============================================="
  echo "  🎉  DEPLOYMENT COMPLETE!"
  echo "=============================================="
  echo "  🌐  Frontend  →  http://$MINIKUBE_IP:30090"
  echo "  ⚙️   Backend   →  http://$MINIKUBE_IP:30080"
  echo "  🗄   MySQL     →  ClusterIP (internal only)"
  echo "=============================================="
  echo ""
  kubectl get all -n "$NAMESPACE"
}

status() {
  echo ""
  info "Resources in namespace: $NAMESPACE"
  kubectl get all -n "$NAMESPACE"
  echo ""
  info "PersistentVolumes"
  kubectl get pv
  echo ""
  MINIKUBE_IP=$(minikube ip)
  echo "  🌐 Frontend  →  http://$MINIKUBE_IP:30090"
  echo "  ⚙️  Backend   →  http://$MINIKUBE_IP:30080"
}

teardown() {
  warn "Deleting all resources in namespace $NAMESPACE..."
  kubectl delete namespace "$NAMESPACE" --ignore-not-found=true
  kubectl delete pv mysql-pv --ignore-not-found=true
  ok "Teardown complete"
}

case "${1:-deploy}" in
  deploy)   deploy   ;;
  status)   status   ;;
  teardown) teardown ;;
  *) echo "Usage: $0 [deploy|status|teardown]"; exit 1 ;;
esac
