
os=$(uname)
is_master=0
if [ $os != Linux ]; then 
    echo "this is not linux"
    exit 1
fi

remove_swap(){
    sudo dphys-swapfile swapoff
    sudo dphys-swapfile uninstall
    sudo apt purge dphys-swapfile -y
    sudo apt autoremove -y
}

install_docker(){
    curl -sSL get.docker.com | sh
    sudo usermod -aG docker pi
}

set_nftable(){
    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
EOF
    sudo sysctl --system
}

set_docker_daemon(){
    cat << EOF | sudo tee /etc/docker/daemon.json
    {
 "exec-opts": ["native.cgroupdriver=systemd"],
 "log-driver": "json-file",
 "log-opts": {
  "max-size": "100m"
 },
 "storage-driver": "overlay2"
}
EOF
sudo systemctl restart docker
}

set_kubernetes_source_list(){
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    sudo apt update
}

install_kubernetes(){
    sudo apt install kubeadm kubectl kubelet
}

set_namespace(){
    mac_address=$(ifconfig eth0 | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}'| tr [a-z] [A-Z])
    if [ $mac_address != '' ]; then
        while read p; do
        address=${p% *}
        if [ $mac_address = $address ]; then
            echo "use hostname:${p#* }"
            hostname="${p#* }"
            break
        fi
        done <$DIR/cluster-info.txt

        if [ hostname != '' ]; then
        echo "set hostname to:$hostname" 
        echo $hostname | sudo tee /etc/hostname
        sudo sed -i "s/raspberrypi/$hostname/g" /etc/hosts 
            if [ "$hostname" != "${hostname/master/}" ]; then
                is_master=1
            fi
        fi
    else
        echo "fail to get mac address"
    fi
}

set_master(){
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --node-name $hostname
    is_success=$?
    if [ $is_success = 0 ]; then 

        if [ -d "$HOME/.kube" ]; then 
            rm -rf $HOME/.kube
        fi
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

        cd $HOME
        git clone --depth 1 https://github.com/coreos/flannel.git
        
        if [ -d "$HOME/flannel" ]; then
            sudo chown $(id -u):$(id -g) $HOME//flannel
            kubectl apply -f $HOME/flannel/Documentation/kube-flannel.yml
        else
            echo "install flannel fail"
        fi
    fi
}

if [ `whoami` = root ]; then
    echo Please dont run this script as root or using sudo
    exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sudo apt update  -y
sudo apt full-upgrade -y
sudo apt install git -y

#remove swap if it is
swap_status=$(which dphys-swapfile)

if [ -f "$swap_status" ]; then 
   echo "need remove swap"
   remove_swap
fi

docker_check=$(which docker)
if [ -f "$docker_check" ]; then
    echo "docker installed"
else 
    echo "need install docker"
    install_docker
fi

if [ -f "/etc/docker/daemon.json" ]; then
    echo "docker daemon had been set"
else
    echo setting docker daemon
    set_docker_daemon
fi

if [ -f "/etc/sysctl.d/k8s.conf" ]; then
    echo "iptable bridge had been set"
else
   echo "setting iptable bridge"
   set_nftable
fi

if [ -f "/etc/apt/sources.list.d/kubernetes.list" ]; then
   echo "source list for kubernetes had been set"
else
   echo "setting up source list for kubenetes"
   set_kubernetes_source_list
fi

kubeadm_check=$(which kubeadm)
if [ -f "$kubeadm_check" ]; then
    echo "kubeadm had been installed"
else
    echo "install kubeadm"
    sudo apt install kubeadm -y
fi

kubectl_check=$(which kubectl)
if [ -f "$kubectl_check" ]; then
    echo "kubectl had been installed"
else
    echo "install kubectl"
    sudo apt install kubectl -y
fi

kubelet_check=$(which kubelet)
if [ -f "$kubelet_check" ]; then
    echo "kubelet had been installed"
else
    echo "install kubelet"
    sudo apt install kubelet -y
fi

set_namespace

sudo chmod +x $DIR/fix-debian.sh
sudo bash $DIR/fix-debian.sh

if [ $is_master = 1 ]; then 
    echo "setting up master"
    set_master
fi

#uncomment this if u want to auto expand partition to full fill the sdcard's space.
#raspi-config --expand-rootfs > /dev/null

#uncomment the line below to remove rpi-cluster helper after setup
#sudo rm -rf $DIR

sudo reboot