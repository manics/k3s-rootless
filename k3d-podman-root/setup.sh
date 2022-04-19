#!/bin/sh

set -eux

dnf copr enable -y -q rhcontainerbot/podman4
dnf install -y -q podman

curl -sfL https://github.com/k3d-io/k3d/releases/download/v5.4.1/k3d-linux-amd64 -o /usr/local/bin/k3d
chmod +x /usr/local/bin/k3d

curl -sfL https://dl.k8s.io/release/v1.23.5/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

systemctl enable --now podman.socket
ln -s /run/podman/podman.sock /var/run/docker.sock
