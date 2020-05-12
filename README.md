# rpi-cluster-helper
This is a bundle of scripts that could help to setup raspberry pi kubernetes cluster.

## Using
After clone or download this bundle, you should may go to rpi-cluster, clone cluster-info-template.txt and rename it to cluster-info.txt. 

Open cluster-info.txt and modify it follow the format  <PI-MAC-ADDRESS> <HOSTNAME> for each raspberry board in your cluster per line. Dont forget add an empty line at the end of file. (Note: if hostname contains 'master' word, that pi will be known at master node)

With each sdcard you will first burn rasbian in it before flug in your computer and do the following steps.

If you use MacOs, just open terminal and exec setup_boot.sh with sudo permission. If you using linux or window, you must finish these follow step manually.
- make an empty file name 'ssh' in boot partition of sdcard
- alter ' cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory ' imtermediaterly after 'rootwait' (with spaces, and on same line)
- copy rpi-cluster folder to boot partition of sdcard. it will be '/boot/rpi-cluster' in your sdcard

Boot your raspberry pi with this sdcard and connect to it using ssh.

When loged in to your raspberry pi. move to /boot/rpi-cluster .
cd /boot/rpi-cluster 

And execute setup.sh without sudo permission.
./setup.sh

## What will script do
Basicly this script will 
1. apt update and upgrade
2. Remove swap
3. Install docker if not existed
4. Change hostname and hosts file bases on defination in cluster-innfo.txt
5. Fix network issue by use iftable-legacy by execute fix-debian.sh (I found in the internet)
6. Install kubeadm kubelet kubectl
7. If this pi is defined as master. init master by using command 'kubeadm init --pod-network-cidr=10.244.0.0/16'. (You shouldn't modify this ip subnet if you are not sure about it.). Setup Flannel as network overlay plugin.


## What will script not do
1. Connect worker node to cluster. You must do this manually by ssh to master node run 'kubeadm token create --print-join-command' to get join commands. And execute these commands in worker nodes with sudo permission.
2. This script doesn't install any load-balancer to cluster.


## If something wrong
When script running maybe some network problem can cause interupt the download processes. In these case just run setup.sh script again, it will be fine.
I only test on newest version of raspbian (Buster).