#!/bin/bash

# Atualizar pacotes do sistema
sudo apt-get update -y
sudo apt-get upgrade -y

# Instalar pacotes necessários para repositórios seguros e o curl
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg

# Criar o diretório de keyrings, necessário para versões mais antigas do Ubuntu (se não existir)
sudo mkdir -p /etc/apt/keyrings

# Adicionar a chave pública para o repositório Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Adicionar o repositório do Kubernetes (repositório comunitário)
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Atualizar a lista de pacotes
sudo apt-get update -y

# Instalar Kubernetes (kubelet, kubeadm, kubectl)
sudo apt-get install -y kubelet kubeadm kubectl

# Marcar as versões para não serem atualizadas automaticamente
sudo apt-mark hold kubelet kubeadm kubectl

# Instalar e iniciar o containerd (runtime de contêiner)
sudo apt-get install -y containerd
# Criar diretório de config se não existir
sudo mkdir -p /etc/containerd

# Gerar configuração padrão e ajustar para SystemdCgroup = true
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Reiniciar containerd com a nova config
sudo systemctl restart containerd
sudo systemctl enable containerd


# Verificar se o containerd está funcionando corretamente
if ! systemctl is-active --quiet containerd; then
  echo "Erro: containerd não está em execução."
  exit 1
fi

# Carregar o módulo 'bridge' necessário para Kubernetes
sudo modprobe bridge

# Carregar o módulo 'br_netfilter' para manipulação de tráfego de rede entre contêineres
sudo modprobe br_netfilter

# Configurar parâmetros do sistema (necessário para o Kubernetes)
echo "1" | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables
echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.conf
echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Desabilitar o swap (necessário para o Kubernetes)
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Inicializar o mestre do Kubernetes
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

# Verificar se o admin.conf foi gerado
if [ ! -f /etc/kubernetes/admin.conf ]; then
  echo "Erro: /etc/kubernetes/admin.conf não encontrado. Verifique se o comando kubeadm init foi bem-sucedido."
  exit 1
fi

# Configurar kubectl para o usuário
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar o plugin de rede (exemplo: Calico)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


# Exibir o comando para adicionar nós workers
echo "Kubernetes master node initialized successfully."
echo "Run the following command on each worker node to join the cluster:"
echo "kubeadm join $(hostname -i):6443 --token <your-token> --discovery-token-ca-cert-hash sha256:<hash>"
