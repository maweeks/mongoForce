ip a
echo "Please input the ip address of the server eth0 here"
read MY_IP
echo "Please input the ip of controller node here"
read CONTROLLER_IP

echo "$CONTROLLER_IP  controller" >> /etc/hosts

apt-get update
apt-get upgrade -y
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana

apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y

apt-get install cinder-volume lvm2 python-mysqldb nova-compute-kvm python-guestfs nova-network -y
chmod 0644 /boot/vmlinuz*



rm /var/lib/nova.sqlite
umount /dev/sdb
pvcreate /dev/sdb -ff
vgcreate cinder-volumes /dev/sdb
vgreduce --removemissing cinder-volumes

for i in c d e f g h i j k l m n o p q r s t u v w x;
do
pvcreate -ff /dev/sd$i; 
vgextend cinder-volumes /dev/sd$i;
done

cp nova-api-paste.ini /etc/nova/api-paste.ini
cp nova.conf /etc/nova/.
cp lvm.conf /etc/lvm/.
cp cinder-api-paste.ini /etc/cinder/api-paste.ini
cp cinder.conf /etc/cinder/.

sed -i -e "s/MY_IP/$MY_IP/g" /etc/nova/nova.conf
sed -i -e "s/CONTROLLER_IP/$CONTROLLER_IP/g" /etc/nova/nova.conf


service nova-compute restart
service nova-network restart
service cinder-volume restart
service tgt restart
