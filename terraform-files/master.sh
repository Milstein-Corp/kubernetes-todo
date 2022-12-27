#! /bin/bash
apt-get update -y
apt-get upgrade -y
apt-get install git -y
hostnamectl set-hostname kube-master
chmod 777 /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
chmod 644 /etc/sysctl.conf
apt install -y docker.io
systemctl start docker
mkdir /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker
usermod -aG docker ubuntu
newgrp docker
apt install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
apt update
apt install -y kubelet=1.25.0-00 kubeadm=1.25.0-00 kubectl=1.25.0-00
systemctl start kubelet
systemctl enable kubelet
kubeadm init --pod-network-cidr=172.16.0.0/16 --ignore-preflight-errors=All
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
su - ubuntu -c 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'
git clone https://github.com/Nihatcan17/kubernetes-todo.git
cd /home/ubuntu/kubernetes-todo/docker-files/client
sed -i "s/'publicipwrittenhere'/${public-ip}/g" .env
cd /home/ec2-user/kubernetes-todo/docker-files/server
sed -i "s/'privateipwrittenhere'/${private-ip}/g" .env
docker build -t "postgres:1.0" /home/ubuntu/kubernetes-todo/docker-files/postgres
docker build -t "nodejs:1.0" /home/ubuntu/kubernetes-todo/docker-files/server
docker build -t "react:1.0" /home/ubuntu/kubernetes-todo/docker-files/client
cd /home/ubuntu/kubernetes-todo/kubernetes-files
su - ubuntu -c 'kubectl apply -f .'