# syntax=docker/dockerfile:1.4

FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

USER root

SHELL ["/bin/bash", "-c"]

# Install base dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    curl ca-certificates make tree unzip git gnupg2 lsb-release apt-transport-https software-properties-common && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# kubectl 1.27.9
RUN curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.27.9/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    kubectl version --client

# argocd 2.8.4
RUN curl -fsSLo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.8.4/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd && \
    argocd version --client

# minikube 1.30.1
RUN curl -fsSLo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/v1.30.1/minikube-linux-amd64 && \
    chmod +x /usr/local/bin/minikube && \
    minikube version

# helm 3.13.3
RUN curl -fsSL https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz | tar -xz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 && \
    helm version

# prometheus 2.48.1
RUN curl -fsSL https://github.com/prometheus/prometheus/releases/download/v2.48.1/prometheus-2.48.1.linux-amd64.tar.gz | tar -xz && \
    mv prometheus-2.48.1.linux-amd64/prometheus /usr/local/bin/prometheus && \
    rm -rf prometheus-2.48.1.linux-amd64 && \
    prometheus --version

# GitHub CLI (latest stable)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && gh --version
