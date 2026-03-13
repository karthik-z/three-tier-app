# 🚀 Three-Tier Application Deployment on Kubernetes (Local)

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)

A production-style **Three-Tier Web Application** deployed locally using **Minikube** (Kubernetes).  
The app is a User Management System with an HTML/JS frontend, Spring Boot REST API, and MySQL database — all running as Kubernetes workloads.

---

## 📐 Architecture

```
                    Browser
                       │
              http://localhost:8090  (Windows/WSL2)
              http://192.168.49.2:30090  (Ubuntu native)
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
    └── frontend-deployment.yaml       # Frontend Deployment + NodePort
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
- ✅ Apply all Kubernetes manifests in correct order
- ✅ Wait for each tier to become Ready
- ✅ Print the access URLs

---

## 🌐 Accessing the Application

### On Ubuntu (Native Linux)
```bash
# Get Minikube IP
minikube ip    # e.g. 192.168.49.2

# Open in browser
http://192.168.49.2:30090             # Frontend UI
http://192.168.49.2:30080/api/users   # Backend API
```

### On Windows via WSL2

Run these commands **every time after reboot:**

**Step 1 — Ubuntu terminal (keep both running):**
```bash
kubectl port-forward -n three-tier service/frontend-service 8090:80 --address 0.0.0.0 &
kubectl port-forward -n three-tier service/backend-service 8081:8080 --address 0.0.0.0 &

# Get your WSL2 IP
hostname -I | awk '{print $1}'
```

**Step 2 — PowerShell (Run as Administrator), replace IP with your WSL2 IP:**
```powershell
netsh interface portproxy add v4tov4 listenport=8090 listenaddress=0.0.0.0 connectport=8090 connectaddress=172.22.177.162
netsh interface portproxy add v4tov4 listenport=8081 listenaddress=0.0.0.0 connectport=8081 connectaddress=172.22.177.162
```

**Step 3 — Open in Windows browser:**
```
http://localhost:8090             # Frontend UI
http://localhost:8081/api/users   # Backend API
```

> ⚠️ WSL2 IP changes on every reboot. Run `hostname -I | awk '{print $1}'` to get the new IP,  
> then run `netsh interface portproxy reset` in PowerShell Admin and repeat Step 2.

---

## 🗄️ Kubernetes Resources

### Tier 1 — MySQL Database

| Resource | Kind | Purpose |
|----------|------|---------|
| `mysql-secret` | Secret | Stores DB credentials (base64 encoded) |
| `mysql-pv` | PersistentVolume | 2Gi hostPath storage for data |
| `mysql-pvc` | PersistentVolumeClaim | Claims the PersistentVolume |
| `mysql-initdb-config` | ConfigMap | Runs init SQL on first boot |
| `mysql` | StatefulSet | Manages MySQL pod with stable identity |
| `mysql-headless` | Service (Headless) | Stable DNS for StatefulSet pods |
| `mysql-service` | Service (ClusterIP) | Internal access for backend on port 3306 |

### Tier 2 — Spring Boot Backend

| Resource | Kind | Purpose |
|----------|------|---------|
| `backend` | Deployment | 1 replica with initContainer waiting for MySQL |
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
| `DELETE` | `/api/users/{id}` | Delete a user by ID |
| `GET` | `/actuator/health` | Health check (used by K8s probes) |

### Example — Create a User
```bash
curl -X POST http://192.168.49.2:30080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Karthik", "email": "karthik@example.com"}'
```

### Example — Get All Users
```bash
curl http://192.168.49.2:30080/api/users
```

---

## 🔑 Default Credentials

| Key | Value |
|-----|-------|
| MySQL Root Password | `rootpassword` |
| MySQL Database | `appdb` |
| MySQL User | `appuser` |
| MySQL Password | `apppassword` |

> ⚠️ To change credentials: `echo -n 'newvalue' | base64` and update `k8s/mysql-secret.yaml`

---

## 🔄 Deploy Script Usage

```bash
./deploy.sh deploy     # Build images + deploy all K8s resources
./deploy.sh status     # Show all running resources + access URLs
./deploy.sh teardown   # Delete all resources and namespace
```

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

# Shell into MySQL pod
kubectl exec -it mysql-0 -n three-tier -- mysql -u appuser -papppassword appdb

# Scale backend replicas
kubectl scale deployment backend --replicas=3 -n three-tier

# Describe a pod (for debugging)
kubectl describe pod <pod-name> -n three-tier
```

---

## 🛑 Stopping the Application

```bash
# Step 1 — Stop port-forwards (WSL2 only)
pkill -f "kubectl port-forward"

# Step 2 — Delete all Kubernetes resources
./deploy.sh teardown

# Step 3 — Stop Minikube
minikube stop
```

| Command | What it does |
|---------|-------------|
| `minikube stop` | Pauses Minikube (resume with `minikube start`) |
| `minikube delete` | ⚠️ Completely removes Minikube cluster |
| `./deploy.sh teardown` | Deletes all K8s resources in namespace |

---

## 🔁 Restarting After a Stop

```bash
# Start Minikube
minikube start --cpus=2 --memory=4096 --driver=docker

# Redeploy the app
cd ~/three-tier-app
./deploy.sh deploy
```

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
