VOLUME_PLUGIN_DIR="/usr/libexec/kubernetes/kubelet-plugins/volume/exec"
mkdir -p "$VOLUME_PLUGIN_DIR/fstab~cifs"
cd "$VOLUME_PLUGIN_DIR/fstab~cifs"
curl -L -O https://raw.githubusercontent.com/fstab/cifs/master/cifs
chmod 755 cifs