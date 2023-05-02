self_path=`readlink -f $0`
ps_path=`dirname $self_path`/photoshop
mkdir $ps_path
url="raw.githubusercontent.com/LinSoftWin/Photoshop-CC2022-Linux/main/scripts/photoshop2021install.sh"
installer="$ps_path/installer.sh"
curl -sSL $url -o $installer
bash $installer $ps_path

