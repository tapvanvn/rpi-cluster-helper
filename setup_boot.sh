function unmount() {
  [[ "$1" == "" ]] && {
      echo "No partition's label specified!";
      return -1;
  }
  disk=$(diskutil list | awk 'BEGIN { last_disk="" } /^\/dev\/disk/ { last_disk=$1 } ($2 ~ /'"$1"'/) || ($3 ~ /'"$1"'/) { print last_disk; exit }')
  [[ "$disk" == "" ]] && {
      echo "Disk with this label not found!";
      return -2;
  }
  diskutil eject "$disk"
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
os=$(uname)
if [ $os != Darwin ]; then 
    echo "this is not macos"
    exit 1
fi

if [ -d '/Volumes/boot' ]; then 
    if [ -f '/Volumes/boot/cmdline.txt' ]; then
        if ! [ -f '/Volumes/boot/ssh' ]; then 
            touch /Volumes/boot/ssh
        fi

        cmdline=$(</Volumes/boot/cmdline.txt)
        if ! [ "$cmdline" != "${cmdline/cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/}" ]; then
            sed -i '.bak' -e 's/rootwait/rootwait cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory/g' /Volumes/boot/cmdline.txt && rm -f /Volumes/boot/cmdline.txt.bak
        fi

        if [ -f "$DIR/rpi-cluster/cluster-info.txt" ]; then
            cp -R $DIR/rpi-cluster/ /Volumes/boot/rpi-cluster/
            rm /Volumes/boot/rpi-cluster/cluster-info-template.txt
        else 
            echo "cluster-info.txt not found please make one and try again"
        fi
        unmount boot
    else
        echo "cmdline.txt not found. something is not correct."
    fi
else
    echo "please insert raspberry pi sdcard"
fi