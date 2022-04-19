# K3d Kubernetes with root Podman

https://k3d.io/v5.4.0/usage/advanced/podman/

Create a new VM, setup Podman 4 including root socket, login:
```
vagrant up
vagrant ssh
```
Switch to root:
```
sudo -i
```
Run (external connection to cluster is currently broken)
```
k3d cluster create
kubectl cluster-info
```
