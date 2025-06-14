

````markdown
# AutoOpsScaler

> **AutoOpsScaler** provides a reproducible, low-ops environment for dynamic infrastructure and deployment automation, built specifically for GenAI engineers. It leverages a devcontainer for local consistency and integrates tightly with Kubernetes, KubeRay, and AWS infrastructure.

---

## 🚀 Getting Started

AutoOpsScaler runs inside a pre-configured [**Dev Container**](https://code.visualstudio.com/docs/devcontainers/containers), ensuring full reproducibility across systems. This guide helps you set up the platform with the **least troubleshooting overhead**.

### ✅ Prerequisites

#### 1. Docker (24.0.7)
A stable Docker installation is mandatory. We strongly recommend using **Linux** or **WSL2 on Windows** for full compatibility with root-based container environments.

<details>
<summary><strong>For Windows (WSL2 Recommended)</strong></summary>

If you're using Docker Desktop + Git Bash, it won't support root-mode devcontainers properly. Switch to WSL2 with Ubuntu 22.04:

1. Uninstall Docker Desktop completely.
2. Open **PowerShell as Administrator** and run:
   ```powershell
   wsl.exe --list --verbose
   wsl.exe --unregister docker-desktop
   wsl.exe --install Ubuntu-22.04
````

3. Launch WSL via:

   * PowerShell: `wsl`
   * VSCode: Click the green corner icon ➝ *"Connect to WSL"*

4. Then install Docker inside WSL:

   ```bash
   sudo apt update
   sudo apt install -y curl docker.io containerd
   sudo usermod -aG docker $USER
   newgrp docker
   ```

</details>

<details>
<summary><strong>For macOS Users</strong></summary>

Ensure you have:

* Docker Desktop installed and running.
* Rosetta installed (for M1/M2 chips).
* Intel-based Docker images may run slower on ARM without tuning.

Refer to: [https://docs.docker.com/desktop/install/mac-install/](https://docs.docker.com/desktop/install/mac-install/)

</details>

<details>
<summary><strong>For Linux Users</strong></summary>

Install Docker:

```bash
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
```

</details>

---

#### 2. Visual Studio Code (VSCode)

While other IDEs are supported, VSCode is **strongly recommended** for zero-friction Dev Container support.

* Install [**VSCode**](https://code.visualstudio.com/)
* Install the extension: **Dev Containers** (by Microsoft)
* Alternatively, install the CLI: [`devcontainer`](https://containers.dev/docs/devcontainer-cli/)

---

## 🛠️ Setup Instructions

### For VSCode Users

```bash
git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler
cd AutoOpsScaler
code .
```

1. Install the **Dev Containers** extension if not already installed.
2. Press `Ctrl + Shift + P` ➝ Select `Dev Containers: Rebuild Container`.
3. Wait for the container to finish provisioning.
4. Close all terminals after the build.
5. Open a new terminal inside the devcontainer:

   ```bash
   make login     # Uses GitHub Personal Access Token (PAT) login only
   make bootstrap # Installs all CLI binaries and Python dependencies
   ```

---

### For Other IDEs / Terminal Users

```bash
git clone https://github.com/Athithya-Sakthivel/AutoOpsScaler
cd AutoOpsScaler
```

1. Manually mount the volume by configuring `.devcontainer/devcontainer.json`.
2. Build the container using the CLI:

   ```bash
   devcontainer build --workspace-folder .
   ```
3. After container setup completes:

   ```bash
   make login
   make bootstrap
   ```

> ❗ JSON doesn't support logic or dynamic expressions, so manual volume binding is required if not using VSCode.

---

## ☸️ Create a Local Kubernetes Cluster (Minikube)

AutoOpsScaler uses Minikube to simulate a production-like cluster for local testing. This is essential to test **KubeRay autoscaling with Karpenter on EKS**.

> ✅ Minikube uses a full VM (via Docker driver) and offers maximum reliability despite a slower startup.

```bash
minikube start --driver=docker --cpus=6 --memory=10g
```

> Ensure Docker is running and your user has access to the Docker socket.

---

## 📌 Platform Notes

* The `.devcontainer/devcontainer.json` defines the build environment.
* All required tools, CLIs, and Python packages are installed via `make bootstrap`.
* GitHub login is required via Personal Access Token (PAT); browser logins are deprecated.
* Local cluster provisioning is necessary for end-to-end testing of autoscaling and infra orchestration features.

---

## 🧠 About the Platform

AutoOpsScaler is purpose-built for:

* GenAI engineers working with dynamic, autoscaling Ray clusters.
* Fully automated and declarative K8s infrastructure (Minikube ➝ EKS).
* Zero-handoff between development and staging environments using containers.

---

## ✅ You're Ready

Start building, deploying, and scaling GenAI workloads without worrying about infrastructure plumbing. Everything is **automated**, **reproducible**, and **battle-tested**.

---

## 🔒 troubleshooting

If anything breaks during container startup or Minikube provisioning, always run:

```bash
docker ps -a && docker logs <container-id>
minikube logs
```

Also, clear volumes and images with:

```bash
docker system prune -af --volumes
minikube delete
```

---
