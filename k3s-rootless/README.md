# Rootless Kubernetes with K3s

https://rancher.com/docs/k3s/latest/en/advanced/#running-k3s-with-rootless-mode-experimental

Create a new VM and setup prerequisites (mostly related to enabling cgroups v2 and delegation)
```
vagrant up
vagrant ssh
```

Copy and paste the commands in [`setup.sh`](./setup.sh)
