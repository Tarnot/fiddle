#!/bin/bash
# Setup for Kubernetes on ARM64 (OrangePi 5)
# k8s-prereqs-arm64.sh
# 9/27/2024
##################################################

# Setup
# TO PREP FOR FRESH DOWNLOAD OF THIS FILE:
#  sudo rm -rf ~/repo/fiddle/; cd ~/repo/; git clone https://github.com/Tarnot/fiddle.git; cd ~/repo/fiddle/k8s-prereqs/; chmod 755 *;
# OR
#  cd ~/repo/fiddle/k8s-prereqs/; git stash; git pull; chmod 755 *;
# THEN
#  sudo ./k8s-prereqs-arm64.sh
##################################################

# Begining of Script
##################################################

echo "Begining of Script";
echo "##################################################";

# Cleanup Old Installation
##################################################

# Return kubernetes to original state
sudo kubeadm reset -f;

# Reset IP tables
sudo iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
sudo ipvsadm -C;

# Uninstall kubernetes
sudo apt-get -y purge --autoremove --allow-change-held-packages kubeadm;
sudo apt-get -y purge --autoremove --allow-change-held-packages kubectl;
sudo apt-get -y purge --autoremove --allow-change-held-packages kubelet;
sudo apt-get -y purge --autoremove --allow-change-held-packages kubernetes-cni;
sudo apt-get -y purge --autoremove --allow-change-held-packages containerd;

# Delete files and directories
sudo rm -rf ~/.kube /etc/cni/;
sudo rm -rf /etc/kubernetes/;
sudo rm -rf /etc/apparmor.d/docker/;
sudo rm -rf /etc/systemd/system/etcd*;
sudo rm -rf /var/lib/dockershim/;
sudo rm -rf /var/lib/etcd/;
sudo rm -rf /var/lib/kubelet/;
sudo rm -rf /var/lib/etcd2/;
sudo rm -rf /var/run/kubernetes/;
sudo rm -rf /opt/cni/;
sudo rm -rf /var/lib/calico/;
sudo rm -rf /var/log/calico/;
sudo rm -rf /var/lib/cni/;
sudo rm -rf /var/log/containers/;
sudo rm -rf /var/log/pods/;
sudo rm -rf /etc/containerd/;
sudo rm -rf /etc/apt/keyrings/kubernetes-apt-keyring.gpg;
sudo rm -rf /etc/apt/sources.list.d/kubernetes.list;
sudo rm -rf /etc/modules-load.d/containerd.conf;
sudo rm -rf /etc/sysctl.d/99-kubernetes-cri.conf;
sudo rm -rf /opt/containerd/;
sudo rm -rf /home/fiddle/install-k8s/;
sudo rm -rf $HOME/.kube/config

# Container Setup
##################################################

# Prep file setup area
mkdir /home/fiddle/install-k8s/;
cd /home/fiddle/install-k8s/;

# Download container files
wget https://github.com/containerd/containerd/releases/download/v1.7.22/containerd-1.7.22-linux-arm64.tar.gz;
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service;
wget https://github.com/opencontainers/runc/releases/download/v1.1.14/runc.arm64;
wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-arm64-v1.5.1.tgz;

# Install container files
sudo tar Cxzvf /usr/local /home/fiddle/install-k8s/containerd-1.7.22-linux-arm64.tar.gz;
sudo cp /home/fiddle/install-k8s/containerd.service /etc/systemd/system/containerd.service;
sudo systemctl daemon-reload;
sudo systemctl enable --now containerd;
sudo install -m 755 /home/fiddle/install-k8s/runc.arm64 /usr/local/sbin/runc;
sudo mkdir -p /opt/cni/bin;
sudo tar Cxzvf /opt/cni/bin /home/fiddle/install-k8s/cni-plugins-linux-arm64-v1.5.1.tgz;

# Networking Setup
##################################################

# Setup k8s.conf modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Apply modprobe
sudo modprobe overlay;
sudo modprobe br_netfilter;

# Setup k8s.conf sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

# Run sysctl
sudo sysctl --system;

# CGroup Setup
##################################################

# Setup containerd
sudo mkdir -p /etc/containerd/;
sudo touch /etc/containerd/config.toml;

# Configure containerd
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

# Restart containerd
sudo systemctl restart containerd;

# Kubetools Setup
##################################################

# Setup k8s access for apt
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg;
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list;

# Setup environment for k8s
sudo swapoff -a;
sudo sed -i 's/\/swap/#\/swap/' /etc/fstab;
sudo apt-get update;
sudo apt-get install -y apt-transport-https ca-certificates curl gpg;

# Install kubetools
sudo apt-get update;
sudo apt-get install -y kubelet kubeadm kubectl;
sudo apt-mark hold kubelet kubeadm kubectl;
sudo systemctl enable --now kubelet;

# End of Script
##################################################

echo "End of Script";
echo "##################################################";

# END
##################################################