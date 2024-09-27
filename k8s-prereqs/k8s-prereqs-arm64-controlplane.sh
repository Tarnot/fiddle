#!/bin/bash
# Setup for Kubernetes Control Plane on ARM64 (OrangePi 5)
# k8s-prereqs-arm64-controlplane
# 9/27/2024
##################################################

# Setup
# See k8s-prereqs-arm64.sh
##################################################

# Begining of Script
##################################################

echo "Begining of Script";
echo "##################################################";

# Variables
##################################################

MYHOME="/home/fiddle"

# Post Installation Configuration
##################################################

# Initialize cluster
sudo kubeadm init --pod-network-cidr=192.168.0.0/23;

# Setup User
mkdir -p $MYHOME/.kube;
sudo chown fiddle:fiddle $MYHOME/.kube;
sudo cp -irf /etc/kubernetes/admin.conf $MYHOME/.kube/config;
sudo chown $(id -u):$(id -g) $MYHOME/.kube/config;
sudo chown fiddle:fiddle $MYHOME/.kube/config;

# Install Calico
sudo -H -u fiddle bash -c 'kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml --validate=false'
cd $MYHOME/install-k8s/;
sudo wget https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml;
sudo chown fiddle:fiddle $MYHOME/install-k8s/custom-resources.yaml;
sudo find $MYHOME/install-k8s/custom-resources.yaml -type f -exec sed -i 's/\/16/\/23/g' {} \;
sudo -H -u fiddle bash -c 'kubectl create -f custom-resources.yaml'

# Print Instructions to Screen
echo "CHECKING CLUSTER:"
sudo -H -u fiddle bash -c 'kubectl cluster-info'
echo "CHECK CALICO:"
echo "watch kubectl get pods -n calico-system;";
echo "sudo kubectl get pods --all-namespaces;";
echo "ON CONTROL PLANE RUN:";
echo "sudo echo 'source <(kubectl completion bash)' >> $MYHOME/.bashrc";
echo "sudo echo 'alias k=kubectl' >> $MYHOME/.bashrc";
echo "sudo echo 'complete -o default -F __start_kubectl k' >> $MYHOME/.bashrc";
echo "source $MYHOME/.bashrc";
echo "RUN ON EACH NODE:";
sudo kubeadm token create --print-join-command;
echo "TO ACCESS kubectl FROM ANOTHER COMPUTER:";
echo "scp root@<control-plane-host>:/etc/kubernetes/admin.conf .;";
echo "kubectl --kubeconfig ./admin.conf get nodes;";

# End of Script
##################################################

echo "End of Script";
echo "##################################################";

# END
##################################################