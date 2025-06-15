# syntax=docker/dockerfile:1.4
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /tmp/bootstrap

SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# --------[ Base System Dependencies ]--------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl ca-certificates unzip git gnupg2 lsb-release apt-transport-https software-properties-common \
      make sudo bash-completion procps iputils-ping iproute2 python3 python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --------[ Install kubectl v1.27.9 ]--------
RUN if ! command -v kubectl >/dev/null 2>&1 || [[ "$(kubectl version --client --output=json | jq -r .clientVersion.gitVersion)" != "v1.27.9" ]]; then \
    curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.27.9/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl ; fi && kubectl version --client=true

# --------[ Install ArgoCD v2.8.4 ]--------
RUN if ! command -v argocd >/dev/null 2>&1 || [[ "$(argocd version --client --short | grep -oP 'v[0-9]+\.[0-9]+\.[0-9]+')" != "v2.8.4" ]]; then \
    curl -fsSLo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.8.4/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd ; fi && argocd version --client

# --------[ Install Minikube v1.30.1 ]--------
RUN if ! command -v minikube >/dev/null 2>&1 || [[ "$(minikube version | head -n1)" != *"v1.30.1"* ]]; then \
    curl -fsSLo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/v1.30.1/minikube-linux-amd64 && \
    chmod +x /usr/local/bin/minikube ; fi && minikube version

# --------[ Install Helm v3.13.3 ]--------
RUN if ! command -v helm >/dev/null 2>&1 || [[ "$(helm version --short)" != "v3.13.3"* ]]; then \
    curl -fsSL https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz | tar -xz && \
    mv linux-amd64/helm /usr/local/bin/helm && rm -rf linux-amd64 ; fi && helm version

# --------[ Install Prometheus v2.48.1 ]--------
RUN if ! command -v prometheus >/dev/null 2>&1 || [[ "$(prometheus --version 2>/dev/null | head -n1)" != "prometheus, version 2.48.1"* ]]; then \
    curl -fsSL https://github.com/prometheus/prometheus/releases/download/v2.48.1/prometheus-2.48.1.linux-amd64.tar.gz | tar -xz && \
    mv prometheus-2.48.1.linux-amd64/prometheus /usr/local/bin/prometheus && rm -rf prometheus-2.48.1.linux-amd64 ; fi && prometheus --version

# --------[ Install GitHub CLI (gh) ]--------
RUN if ! command -v gh >/dev/null 2>&1; then \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh ; fi && gh --version

# --------[ Install Pulumi v3.95.0 ]--------
RUN if ! command -v pulumi >/dev/null 2>&1 || [[ "$(pulumi version)" != "3.95.0" ]]; then \
    curl -fsSL https://get.pulumi.com/releases/sdk/pulumi-v3.95.0-linux-x64.tar.gz | tar -xz && \
    mv pulumi/* /usr/local/bin/ && rm -rf pulumi ; fi && pulumi version

# --------[ Preinstall Pulumi AWS Plugin v5.44.0 ]--------
RUN pulumi plugin ls | grep 'aws.*v5.44.0' || pulumi plugin install resource aws v5.44.0 --yes

# --------[ Install AWS CLI v2.13.21 ]--------
RUN if ! command -v aws >/dev/null 2>&1 || [[ "$(aws --version 2>&1)" != *"2.13.21"* ]]; then \
    apt-get update && apt-get install -y unzip curl groff less && \
    curl -fsSLo awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.13.21.zip && \
    unzip -q awscliv2.zip && ./aws/install --update && \
    rm -rf aws awscliv2.zip ; fi && aws --version

# --------[ Docker-in-Docker Rootless Support (optional) ]--------
RUN dockerd-rootless-setuptool.sh install || true

# Final container state
WORKDIR /workspaces/AutoOpsScaler
CMD [ "sleep", "infinity" ]
