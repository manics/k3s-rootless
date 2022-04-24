#!/bin/sh

set -eu

. /etc/os-release

REBOOT=0
COMMON_PKGS="curl fuse-overlayfs openssl socat tar vim"

if [ "$ID" = fedora -o "$ID" = centos -o "$ID" = rhel -o "$ID" = rocky ]; then
  sudo dnf install -y $COMMON_PKGS shadow-utils
elif [ "$ID" = ubuntu -o "$ID" = debian ]; then
  sudo apt-get -y -q update
  sudo apt-get -y -q install $COMMON_PKGS uidmap
else
  echo "Unsupported OS: $ID"
  exit 1
fi

if [ "$(sysctl net.ipv4.ip_forward -n)" != "1" ]; then
  echo "Enabling IP forwarding"
  cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf
net.ipv4.ip_forward = 1
EOF
  REBOOT=1
fi

if [ ! -f /sys/fs/cgroup/cgroup.controllers ]; then
  echo "Enabling cgroup v2 unified hierarchy"
  if [ ! -x /usr/sbin/update-grub -a ! -x /usr/sbin/grub2-mkconfig ]; then
    echo "Unable to update grub, please update manually"
    exit 1
  fi

  sudo sed -i -e 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="systemd.unified_cgroup_hierarchy=1 cgroup_no_v1=all /' /etc/default/grub

  if [ -x /usr/sbin/update-grub ]; then
    sudo /usr/sbin/update-grub
  else [ -x /usr/sbin/grub2-mkconfig ];
    sudo "/usr/sbin/grub2-mkconfig" -o "/boot/grub2/grub.cfg"
  fi
  REBOOT=1
fi

# Enable CPU, CPUSET, and I/O delegation
# https://rootlesscontaine.rs/getting-started/common/cgroup2/#enabling-cpu-cpuset-and-io-delegation

if [ "$(cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers)" != "cpuset cpu io memory pids" ]; then
  echo "Enabling cgroup v2 delegation"
  sudo mkdir -p /etc/systemd/system/user@.service.d
  cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF

  # Additional steps for RHEL8 https://unix.stackexchange.com/a/625079
  if [ "$ID" = centos -o "$ID" = rhel -o "$ID" = rocky ]; then
    cat <<EOF | sudo tee /etc/systemd/system/user-0.slice
[Unit]
Before=systemd-logind.service
[Slice]
Slice=user.slice
[Install]
WantedBy=multi-user.target
EOF

    sudo mkdir -p /etc/systemd/system/user-.slice.d
    cat <<EOF | sudo tee /etc/systemd/system/user-.slice.d/override.conf
[Slice]
Slice=user.slice

CPUAccounting=yes
MemoryAccounting=yes
IOAccounting=yes
TasksAccounting=yes[Slice]
Slice=user.slice

CPUAccounting=yes
MemoryAccounting=yes
IOAccounting=yes
TasksAccounting=yes
EOF
  fi

  sudo systemctl daemon-reload
  REBOOT=1
fi

if [ "$REBOOT" = "1" ]; then
  echo "Reboot required"
  sudo reboot
fi
