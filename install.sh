#!/bin/bash
echo "Start creating Kiosk Box.";
read -p 'Input auto login ID and enter (just enter for disable it): ' i;
read -p 'Input firefox default site and enter(default:https://www.google.com/): ' w;
if $w; then
    w="https://www.google.com/";
fi

echo "Update system."
apt update && apt upgrade;
apt install -y xorg openbox firefox-esr;

# Turn off all ttyN except tty1
if [ -f "/etc/systemd/logind.conf" ]; then
    R="ReserverVT=1";
    if ! grep -Fxq "$R" /etc/systemd/logind.conf; then
        sed -i '/\[Login\]/a ReserverVT=1' /etc/systemd/logind.conf;
    fi
    N="NAutoVTs=1";
    if ! grep -Fxq "$N" /etc/systemd/logind.conf; then
        sed -i '/\[Login\]/a NAutoVTs=1' /etc/systemd/logind.conf;
    fi 
fi

# Auto login
printf "Make auto login..."
if [ ! -z $i ]; then
    mkdir -p /etc/systemd/system/getty@tty1.service.d;
    if [ -d "/etc/systemd/system/getty@tty1.service.d" ]; then
        touch /etc/systemd/system/getty@tty1.service.d/override.conf;
        echo -e "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin $i --noclear %I 38400 linux" > /etc/systemd/system/getty@tty1.service.d/override.conf;
        systemctl enable getty@tty1.service
    fi
    if [ -d "/home/$1" ]; then
        echo 'if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then exec startx; fi' >> /home/$i/.bashrc;
    fi
    echo " done."
else
    echo "$i does not exist!"
fi

# Auto run firefox
touch /usr/local/bin/run-firefox.sh
chmod +x /usr/local/bin/run-firefox.sh
echo '#!/bin/bash' > /usr/local/bin/run-firefox.sh
echo -e "while \[ 1 \];\ndo \n\tfirefox -ssb $w\ndone" >> /usr/local/bin/run-firefox.sh
echo -e '# Keep screen on\nxset -dpms\nxset s off\nxset s noblank\nsleep 15\n/usr/local/bin/run-firefox.sh &' >> /etc/xdg/openbox/autostart

# Default firefox setting
sed -i '/<\/applications>/i <application class="Firefox*">' /etc/xdg/openbox/rc.xml
sed -i '/<\/applications>/i <maximized>yes<\/maximized>' /etc/xdg/openbox/rc.xml
sed -i '/<\/applications>/i <decor>no<\/decor>' /etc/xdg/openbox/rc.xml
sed -i '/<\/applications>/i <\/application>' /etc/xdg/openbox/rc.xml

# Add keyboard shortcuts for term
sed -i '/<\/keyboard>/i <keybind key="C-A-t">' /etc/xdg/openbox/rc.xml
sed -i '/<\/keyboard>/i <action name="Execute">' /etc/xdg/openbox/rc.xml
sed -i '/<\/keyboard>/i <command>x-terminal-emulator<\/command>' /etc/xdg/openbox/rc.xml
sed -i '/<\/keyboard>/i <\/action>' /etc/xdg/openbox/rc.xml
sed -i '/<\/keyboard>/i <\/keybind>' /etc/xdg/openbox/rc.xml

# Add keyboard shortcut for restart x
sed -i '/<\/keyboard>/i <keybind key="C-A-r">' /etc/xdg/openbox/rc.xml
sed -i '/<\/keyboard>/i <action name="Restart" \/>' /etc/xdg/openbox/rc.xml
sed -i '/<\/keyboard>/i <\/keybind>' /etc/xdg/openbox/rc.xml

# Remove ctrl-alt-del
systemctl mask ctrl-alt-del.target

# Restart
read -p 'All done, restart system?(Y/N): ' l
if [ $l = "Y" ] | [ $l = "y" ]; then
    /sbin/reboot
fi