#!/bin/bash
# Setup for Kubernetes Control Plane on ARM64 (OrangePi 5)
# k8s-prereqs-arm64-controlplane
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

# Post Installation Configuration
##################################################

# Check Installation - https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
#sudo kubectl cluster-info;

# echo instructions
echo "ON CONTROL PLANE RUN:";
echo "          sudo echo 'source <(kubectl completion bash)' >> ~/.bashrc";
echo "          sudo echo 'alias k=kubectl' >> ~/.bashrc";
echo "          sudo echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc";
echo "          source ~/.bashrc";
echo "          sudo kubeadm init --pod-network-cidr=192.168.0.0/23;";
echo "          sudo kubectl cluster-info;";
echo "          ##################################################";
echo "          sudo mkdir -p $HOME/.kube;";
echo "          sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;";
echo "          sudo chown $(id -u):$(id -g) $HOME/.kube/config;";
echo "          ##################################################";
#echo "          sudo kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml;";
echo "          sudo kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml --validate=false;";
echo "          cd ~/install-k8s/;";
echo "          sudo wget https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml;";
echo "          sudo find ~/install-k8s/custom-resources.yaml -type f -exec sed -i 's/16/23/g' {} \;";
echo "          kubectl create -f custom-resources.yaml;";
echo "          sudo kubectl taint nodes --all node-role.kubernetes.io/control-plane-;";
echo "          watch kubectl get pods -n calico-system;";
echo "          sudo kubectl get pods --all-namespaces;";

echo "          sudo kubeadm token create --print-join-command;";
echo "COPY RESULTING TEXT";
echo "RUN ON EACH NODE (SOMETHING LIKE):";
echo "          kubeadm join 192.168.254.210:6443 --token 6yglpi.f3tcar2s4qybckr7 --discovery-token-ca-cert-hash sha256:ad71aac8aff7ee25cf0eb5725a54c4990d0016849ace302d9235b3adcab57374";
echo "TO ACCESS kubectl FROM ANOTHER COMPUTER:";
echo "          scp root@<control-plane-host>:/etc/kubernetes/admin.conf .;";
echo "          kubectl --kubeconfig ./admin.conf get nodes;";





# End of Script
##################################################

echo "End of Script";
echo "##################################################";

# END
##################################################