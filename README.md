# 🚀 Three-Tier Application Deployment on Kubernetes (Local)

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)

A production-style **Three-Tier Web Application** deployed locally using **Minikube** (Kubernetes).  
The app is a User Management System with a React-style frontend, Spring Boot REST API, and MySQL database — all running as Kubernetes workloads.

---

## 📐 Architecture

```
                    Browser
                       │
              http://<minikube-ip>:30090
                       │
            ┌──────────▼──────────┐
            │   Frontend (Nginx)   │   Deployment + NodePort :30090
            │     frontend-ui      │
            └──────────┬───────────┘
                       │  /api/ proxy
            ┌──────────▼──────────┐
            │   Spring Boot API    │   Deployment + NodePort :30080
            │  springboot-backend  │
            └──────────┬───────────┘
                       │  JDBC (port 3306)
            ┌──────────▼──────────┐
            │     MySQL 8.0        │   StatefulSet + Headless Service
            │      mysql-0         │   PersistentVolume (2Gi)
            └──────────────────────┘

            └─────── Namespace: three-tier ────────┘
```

---

## 📁 Project Structure

```
three-tier-app/
├── deploy.sh                          # One-command deploy / teardown script
│
├── backend/                           # Spring Boot Application
│   ├── Dockerfile                     # Multi-stage Maven → JRE build
│   ├── pom.xml                        # Maven dependencies
│   └── src/main/
│       ├── java/com/example/demo/
│       │   ├── DemoApplication.java   # Spring Boot entry point
│       │   ├── controller/
│       │   │   └── UserController.java  # REST API endpoints
│       │   ├── model/
│       │   │   └── User.java          # JPA Entity
│       │   └── repository/
│       │       └── UserRepository.java # Spring Data JPA
│       └── resources/
│           └── application.properties # DB config (env-driven)
│
├── frontend/                          # HTML/JS/CSS UI served by Nginx
│   ├── Dockerfile                     # Nginx image
│   ├── index.html                     # Single-page User Management UI
│   └── nginx.conf                     # Nginx config with API proxy
│
└── k8s/                               # Kubernetes Manifests
    ├── namespace.yaml                 # three-tier namespace
    ├── mysql-secret.yaml              # DB credentials (base64)
    ├── mysql-pv.yaml                  # PersistentVolume + PVC (2Gi)
    ├── mysql-configmap.yaml           # DB init SQL
    ├── mysql-statefulset.yaml         # StatefulSet + Headless + ClusterIP
    ├── backend-deployment.yaml        # Backend Deployment + NodePort
    └── frontend-deployment.yaml      # Frontend Deployment + NodePort
```

---

## 🧰 Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker | ≥ 24 | [docs.docker.com](https://docs.docker.com/get-docker/) |
| Minikube | ≥ 1.32 | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |
| kubectl | ≥ 1.28 | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |

---

## ⚡ Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/karthik-z/three-tier-app.git
cd three-tier-app
```

### 2. Start Minikube
```bash
minikube start --cpus=2 --memory=4096 --driver=docker
```

### 3. Deploy Everything (One Command)
```bash
chmod +x deploy.sh
./deploy.sh deploy
```

The script will automatically:
- ✅ Point Docker at Minikube's internal daemon
- ✅ Build `springboot-backend:latest` image (~3 min Maven build)
- ✅ Build `frontend-ui:latest` image (~30 sec)
- ✅ Apply all Kubernetes manifests in order
- ✅ Wait for each tier to become Ready
- ✅ Print the access URLs

### 4. Access the Application
```bash
# Get Minikube IP
minikube ip

# Open in browser
http://<minikube-ip>:30090        # Frontend UI
http://<minikube-ip>:30080/api/users  # Backend API
```

---

## 🗄️ Kubernetes Resources

### Tier 1 — MySQL Database

| Resource | Kind | Purpose |
|----------|------|---------|
| `mysql-secret` | Secret | Stores DB credentials (base64) |
| `mysql-pv` | PersistentVolume | 2Gi hostPath storage |
| `mysql-pvc` | PersistentVolumeClaim | Claims the PV |
| `mysql-initdb-config` | ConfigMap | Runs init SQL on first boot |
| `mysql` | StatefulSet | Manages MySQL pod with stable identity |
| `mysql-headless` | Service (Headless) | Stable DNS for StatefulSet pods |
| `mysql-service` | Service (ClusterIP) | Internal access for backend |

### Tier 2 — Spring Boot Backend

| Resource | Kind | Purpose |
|----------|------|---------|
| `backend` | Deployment | 1 replica, with MySQL initContainer wait |
| `backend-service` | Service (NodePort) | Exposes API on port `30080` |

### Tier 3 — Frontend UI

| Resource | Kind | Purpose |
|----------|------|---------|
| `frontend` | Deployment | 1 replica Nginx server |
| `frontend-service` | Service (NodePort) | Exposes UI on port `30090` |

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/users` | Get all users |
| `POST` | `/api/users` | Create a new user |
| `DELETE` | `/api/users/{id}` | Delete a user |
| `GET` | `/actuator/health` | Health check (used by K8s probes) |

### Example — Create a User
```bash
curl -X POST http://<minikube-ip>:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Karthik", "email": "karthik@example.com"}'
```

### Example — Get All Users
```bash
curl http://<minikube-ip>:30080/api/users
```

---

## 🔑 Default Credentials

| Key | Value |
|-----|-------|
| MySQL Root Password | `rootpassword` |
| MySQL Database | `appdb` |
| MySQL User | `appuser` |
| MySQL Password | `apppassword` |

> ⚠️ To change credentials, encode with `echo -n 'newvalue' | base64` and update `k8s/mysql-secret.yaml`.

---

## 🛠️ Useful Commands

```bash
# Check all resources
kubectl get all -n three-tier

# Watch pods in real time
kubectl get pods -n three-tier -w

# View backend logs
kubectl logs -f deployment/backend -n three-tier

# View frontend logs
kubectl logs -f deployment/frontend -n three-tier

# Shell into MySQL
kubectl exec -it mysql-0 -n three-tier -- mysql -u appuser -papppassword appdb

# Scale backend to 3 replicas
kubectl scale deployment backend --replicas=3 -n three-tier

# Check service URLs
minikube service list

# Teardown everything
./deploy.sh teardown

# Check status
./deploy.sh status
```

---

## 🔄 Deploy Script Usage

```bash
./deploy.sh deploy     # Build images + deploy all K8s resources
./deploy.sh status     # Show all running resources + access URLs
./deploy.sh teardown   # Delete all resources and namespace
```

---

## 🖥️ Accessing from Windows (WSL2)

If you're running Ubuntu in WSL2 and want to access from Windows browser:

```bash
# Port-forward frontend
kubectl port-forward -n three-tier service/frontend-service 8090:80 --address 0.0.0.0

# Get your Ubuntu IP
hostname -I | awk '{print $1}'

# Open in Windows browser
http://<ubuntu-ip>:8090
```

---

## 📸 Screenshot

![Three-Tier App UI](https://i.imgur.com/placeholder.png)
> User Management UI — Add, view, and delete users stored in MySQL via Spring Boot API.

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Container Orchestration | Kubernetes (Minikube) |
| Frontend | HTML5, CSS3, JavaScript, Nginx |
| Backend | Java 17, Spring Boot 3.2, Spring Data JPA |
| Database | MySQL 8.0 |
| Containerization | Docker (multi-stage builds) |
| Build Tool | Maven 3.9 |

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

<div align="center">
  <p>Built with ❤️ by <a href="https://github.com/karthik-z">karthik-z</a></p>
  <p>⭐ Star this repo if you found it helpful!</p>
</div>
