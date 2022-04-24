#!/bin/sh

set -eu

mkdir -p ~/bin
curl -sfL https://github.com/k3s-io/k3s/releases/download/v1.23.5%2Bk3s1/k3s -o ~/bin/k3s
chmod +x ~/bin/k3s
ln -s k3s ~/bin/kubectl

mkdir -p ~/.config/systemd/user

# Based on https://github.com/k3s-io/k3s/blob/v1.23.5+k3s1/k3s-rootless.service
cat << EOF > ~/.config/systemd/user/k3s-rootless.service
# systemd unit file for k3s (rootless)
#
# Troubleshooting:
# - See 'systemctl --user status k3s-rootless' to check the daemon status
# - See 'journalctl --user -f -u k3s-rootless' to see the daemon log
# - See also https://rootlesscontaine.rs/

[Unit]
Description=k3s (Rootless)

[Service]
Environment=PATH=%h/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# NOTE: Don't try to run 'k3s server --rootless' on a terminal, as it doesn't enable cgroup v2 delegation.
# If you really need to try it on a terminal, prepend 'systemd-run --user -p Delegate=yes --tty' to create a systemd scope.
ExecStart=%h/bin/k3s server --rootless --snapshotter=fuse-overlayfs --debug -v 3
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
#Restart=always
Restart=no
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
Type=simple
KillMode=mixed

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now k3s-rootless

# journalctl --user -u k3s-rootless -fl

start=`date +%s`
# 5 mins
timeout=300
while ! ~/bin/kubectl cluster-info > /dev/null 2> /dev/null; do
  now=`date +%s`
  t=$(($now-$start))
  if [ $t -gt $timeout ]; then
    echo "[$t s] Timeout waiting for k3s to start"
    exit 1
  fi
  echo "[$t s] Waiting for k3s to start ...."
  sleep 10
done

ln -s ~/.kube/k3s.yaml ~/.kube/config

curl -sfL https://get.helm.sh/helm-v3.8.2-linux-amd64.tar.gz | tar -xz -C ~/bin --strip-components=1 linux-amd64/helm

# RHEL:
# sudo modprobe ip_tables

# Ubuntu:
# export PATH=~/bin:$PATH
