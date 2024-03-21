#!/bin/bash
# Setup for Kubernetes
# k8s-prereqs.sh
##############################

# Cleanup
####################
sudo kubeadm reset -f; sudo apt-get -y purge --autoremove --allow-change-held-packages kubeadm kubectl kubelet kubernetes-cni containerd; sudo rm -rf ~/.kube /etc/cni /etc/kubernetes /etc/apparmor.d/docker /etc/systemd/system/etcd* /var/lib/dockershim /var/lib/etcd /var/lib/kubelet /var/lib/etcd2/ /var/run/kubernetes /opt/cni /var/lib/calico /var/log/calico /var/lib/cni /var/log/containers/ /var/log/pods/ /etc/containerd/ /etc/apt/keyrings/kubernetes-apt-keyring.gpg /etc/modules-load.d/containerd.conf /etc/sysctl.d/99-kubernetes-cri.conf; sudo rm -rf /opt/containerd/

# Container Setup
####################

# Prep setup area
mkdir /home/fiddle/install-k8s/
cd /home/fiddle/install-k8s/

# Download container files
wget https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-arm64.tar.gz
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.arm64
wget https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-arm64-v1.4.1.tgz

# Install container files
sudo tar Cxzvf /usr/local /home/fiddle/install-k8s/containerd-1.7.14-linux-arm64.tar.gz
sudo cp /home/fiddle/install-k8s/containerd.service /etc/systemd/system/containerd.service
sudo systemctl daemon-reload 
sudo systemctl enable --now containerd
sudo install -m 755 /home/fiddle/install-k8s/runc.arm64 /usr/local/sbin/runc
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin /home/fiddle/install-k8s/cni-plugins-linux-arm64-v1.4.1.tgz

# Networking Setup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# CGroup Setup
sudo mkdir -p /etc/containerd/
sudo touch /etc/containerd/config.toml

cat <<- TOML | sudo tee /etc/containerd/config.toml
version = 2
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.k8s.io/pause:3.9"
    [plugins."io.containerd.grpc.v1.cri".containerd]
      discard_unpacked_layers = true
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
TOML

sudo systemctl restart containerd

# Kubetools Setup
####################
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet
