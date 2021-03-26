#!/bin/bash
#Before running this script, set up your ssh key and add it to the gitlab and github accounts.
#Also configure vpn access before running
if [ $(id -u) = 0 ]; then
   echo "This script changes your users gsettings and should thus not be run as root!"
   echo "You may need to enter your password multiple times!"
   exit 1
fi


while test $# -gt 0
do
    case "$1" in
        --nonfree) 
			echo "Nonfree Additions will be added"
			NONFREE=true
            ;;
    esac
    shift
done


# Some Kernel/Usability Improvements
sudo tee -a /etc/sysctl.d/40-max-user-watches.conf > /dev/null  <<EOF
fs.inotify.max_user_watches=524288
EOF

# Some Kernel/Usability Improvements
sudo tee -a /etc/sysctl.d/99-network.conf > /dev/null  <<EOF
net.ipv4.ip_forward=0
net.ipv4.tcp_ecn=1
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

sudo tee -a /etc/sysctl.d/99-swappiness.conf > /dev/null  <<EOF
vm.swappiness=1
EOF


###
# Optionally clean all dnf temporary files
###

sudo dnf clean all

###
# RpmFusion Free Repo
# This is holding only open source, vetted applications - fedora just cant legally distribute them themselves thanks to 
# Software patents
###

sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 

###
# RpmFusion NonFree Repo
# This includes Nvidia Drivers and more
###

if [ ! -z "$NONFREE" ]; then
	sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi


###
# Disable the Modular Repos
# Given the added load at updates, and the issues to keep modules updated, in check and listed from the awful cli for it - remove entirely.
###

sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-updates-modular.repo
sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-modular.repo

# Testing Repos should be disabled anyways
sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-updates-testing-modular.repo
sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/rpmfusion-free-updates-testing.repo

# Rpmfusion makes this obsolete
sudo sed -i 's/enabled=1/enabled=0/g' /etc/yum.repos.d/fedora-cisco-openh264.repo

# Disable Machine Counting for all repos
sudo sed -i 's/countme=1/countme=0/g' /etc/yum.repos.d/*

###
# Force update the whole system to the latest and greatest
###

sudo dnf upgrade --best --allowerasing --refresh -y

# And also remove any packages without a source backing them
sudo dnf distro-sync -y

###
# Install base packages and applications
###

sudo dnf install \
-y \
arc-theme `#A more comfortable GTK/Gnome-Shell Theme` \
breeze-cursor-theme `#A more comfortable Cursor Theme from KDE` \
darktable `#Easy RAW Editor` \
exfat-utils `#Allows managing exfat (android sd cards and co)` \
ffmpeg `#Adds Codec Support to Firefox, and in general` \
file-roller-nautilus `#More Archives supported in nautilus` \
fuse-exfat `#Allows mounting exfat` \
fuse-sshfs `#Allows mounting servers via sshfs` \
git `#VCS done right` \
git-crypt \
golang \
gnome-shell-extension-dash-to-dock `#dash for gnome` \
gnome-shell-extension-user-theme `#Enables theming the gnome shell` \
gnome-tweaks `#Your central place to make gnome like you want` \
gvfs-fuse `#gnome<>fuse` \
gvfs-mtp `#gnome<>android` \
gvfs-nfs `#gnome<>ntfs` \
gvfs-smb `#gnome<>samba` \
htop `#Cli process monitor` \
lm_sensors `#Show your systems Temparature` \
'mozilla-fira-*' `#A nice font family` \
mpv `#The best media player (with simple gui)` \
nautilus-extensions `#What it says on the tin` \
nautilus-image-converter \
nautilus-search-tool \
NetworkManager-openvpn-gnome `#To enforce that its possible to import .ovpn files in the settings` \
openssh-askpass `#Base Lib to let applications request ssh pass via gui` \
papirus-icon-theme `#A quite nice icon theme` \
pv `#pipe viewer - see what happens between the | with output | pv | receiver ` \
python3-devel `#Python Development Gear` \
python3-neovim `#Python Neovim Libs` \
rawtherapee `#Professional RAW Editor` \
spamassassin `#Dep to make sure it is locally installed for Evolution` \
telegram-desktop `#Chatting, with newer openssl and qt base!` \
tilix `#The best terminal manager i know of` \
tilix-nautilus `#Adds right click open in tilix to nautilus` \
transmission `#Torrent Client` \
tuned `#Tuned can optimize your performance according to metrics. tuned-adm profile powersave can help you on laptops, alot` \
unar `#free rar decompression` \
vagrant `#Virtual Machine management and autodeployment` \
vagrant-libvirt `#integration with libvirt` \
virt-manager `#A gui to manage virtual machines` \
wavemon `#a cli wifi status tool` \
youtube-dl `#Allows you to download and save youtube videos but also to open their links by dragging them into mpv!` \
ansible `#Awesome to manage multiple machines or define states for systems` \
adobe-source-code-pro-fonts `#The most beautiful monospace font around` \
borgbackup `#If you need backups, this is your tool for it` \
nano `#Because pressing i is too hard sometimes` \
tig `#cli git tool` \
zsh `#Best shell` \
zsh-syntax-highlighting `#Now with syntax highlighting` \
libguestfs-tools `#Resize Vm Images and convert them` \
ncdu `#Directory listing CLI tool. For a gui version take a look at "baobab"` \

###
# Remove some un-needed stuff
###

sudo dnf remove \
-y \
totem `#With mpv installed totem became a little useless` \
chromium `#Using Chromium resets chromium-vaapi so remove it if installed, userprofiles will be kept and can be used in -vaapi`

###
# Enable some of the goodies, but not all
# Its the users responsibility to choose and enable zsh, with oh-my-zsh for example
# or set a more specific tuned profile
###

sudo systemctl enable --now tuned
sudo tuned-adm profile balanced

#Performance:
#sudo tuned-adm profile desktop

#Virtual Machine Host:
#sudo tuned-adm profile virtual-host

#Virtual Machine Guest:
#sudo tuned-adm profile virtual-guest

#Battery Saving:
#sudo tuned-adm profile powersave

# Virtual Machines
sudo systemctl enable --now libvirtd

# Management of local/remote system(s) - available via http://localhost:9090
sudo systemctl enable --now cockpit.socket

###
# Theming and GNOME Options
###


# Tilix Dark Theme
gsettings set com.gexperts.Tilix.Settings theme-variant 'dark'

#Gnome Shell Theming
gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Breeze_Snow'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.shell.extensions.user-theme name 'Arc-Dark-solid'

#Set SCP as Monospace (Code) Font
gsettings set org.gnome.desktop.interface monospace-font-name 'Source Code Pro Semi-Bold 12'

#Set Extensions for gnome
gsettings set org.gnome.shell enabled-extensions "['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com']"

#Better Font Smoothing
gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing 'rgba'

#Usability Improvements
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'adaptive'
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
gsettings set org.gnome.desktop.calendar show-weekdate true
gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell.overrides workspaces-only-on-primary false

#Dash to Dock Theme
gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme false
gsettings set org.gnome.shell.extensions.dash-to-dock custom-background-color false
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-customize-running-dots true
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-color '#729fcf'
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
gsettings set org.gnome.shell.extensions.dash-to-dock force-straight-corner false
gsettings set org.gnome.shell.extensions.dash-to-dock icon-size-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide-mode 'ALL_WINDOWS'
gsettings set org.gnome.shell.extensions.dash-to-dock isolate-workspaces true
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
gsettings set org.gnome.shell.extensions.dash-to-dock unity-backlit-items false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'SEGMENTED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.70000000000000000
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

#This indexer is nice, but can be detrimental for laptop users battery life
gsettings set org.freedesktop.Tracker.Miner.Files index-on-battery false
gsettings set org.freedesktop.Tracker.Miner.Files index-on-battery-first-time false
gsettings set org.freedesktop.Tracker.Miner.Files throttle 15

#Nautilus (File Manager) Usability
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'
gsettings set org.gnome.nautilus.preferences executable-text-activation 'ask'
gsettings set org.gtk.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.nautilus.list-view use-tree-view trueC

#Gnome Night Light (Like flux/redshift)
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 9.0
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 18.0


# Steam games (32bit) have issues with the too new 32bit compat libs in fedora
# Flatpak is the better option here
if [ ! -z "$STEAMFLAT" ]; then
	sudo dnf install -y flatpak
    flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install --user flathub com.valvesoftware.Steam

    flatpak remote-add --if-not-exists --user freedesktop-sdk https://cache.sdk.freedesktop.org/freedesktop-sdk.flatpakrepo

    #To run it with mesa-aco:
    #FLATPAK_GL_DRIVERS=mesa-aco flatpak run com.valvesoftware.Steam
	# Installed but not displayed? Check with: flatpak run com.valvesoftware.Steam
fi

#The user needs to reboot to apply all changes.
mkdir /home/jkiely/dev/
cd /home/jkiely/dev/
git clone git@github.com:jjkiely/integreatly-operator.git
cd integreatly-operator
git remote add upstream git@github.com:integr8ly/integreatly-operator.git
cd /home/jkiely/dev/
git clone git@github.com:jjkiely/delorean.git
cd delorean
git remote add upstream git@github.com:integr8ly/delorean.git
cd /home/jkiely/dev/
git clone git@github.com:jjkiely/zshrc.git
git clone git@gitlab.cee.redhat.com:jkiely/ci-cd.git
cd ci/cd
git remote add upstream git@gitlab.cee.redhat.com:integreatly-qe/ci-cd.git
cd /home/jkiely/dev/
echo "Please Reboot" && exit 0