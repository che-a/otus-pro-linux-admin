#!/usr/bin/env bash
mkdir -p ~root/.ssh
cp ~vagrant/.ssh/auth* ~root/.ssh

mkdir -p /home/vagrant/fake_srv/
cp /vagrant/access1.log /home/vagrant/fake_srv/access1.log.source
cp /vagrant/access2.log /home/vagrant/fake_srv/access2.log.source
chown -R vagrant:vagrant /home/vagrant/fake_srv

yum install -y mc nano tree

# ===
OUTFILE="/home/vagrant/fake_srv/fake_srv.sh"
(
cat <<- '_EOF_'
#!/usr/bin/env bash
SRV_NAME='fake_srv'
SRV_DIR="/home/vagrant/fake_srv/"
SRV_LOG=$SRV_DIR$SRV_NAME'.log'
#cat access*.log.source > $SRV_LOG'.source'
#WC_SOURCE=`cat $SRV_LOG'.source' | wc -l`
#sed -i 's/[.*]/[AOAOAOAOAOAO]/' $SRV_LOG'.source'
while [ true ]; do
    sleep 1
done
_EOF_
) > $OUTFILE
chown -R vagrant:vagrant $OUTFILE
chmod +x $OUTFILE

# ====
SERVICE_FILE='fake_srv.service'
SERVICE_PATH='/etc/systemd/system/'$SERVICE_FILE

touch $SERVICE_PATH
chmod 664 $SERVICE_PATH

cat > $SERVICE_PATH <<'_EOF_'

[Unit]
Description=FakeWebServer
After=network.target

[Service]
Type=simple
ExecStart=/home/vagrant/fake_srv/fake_srv.sh
Restart=always
User=vagrant

[Install]
WantedBy=multi-user.target

_EOF_

systemctl enable fake_srv.service
systemctl start fake_srv.service
