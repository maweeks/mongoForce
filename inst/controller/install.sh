ip a
echo "Please input the ip address of the server eth0 here"
read MY_IP
echo "$MY_IP  controller" >> /etc/hosts

apt-get update
apt-get upgrade -y
apt-get install python-software-properties -y
add-apt-repository cloud-archive:havana

apt-get update
apt-get dist-upgrade -y
apt-get upgrade -y

apt-get install -y mysql-server python-mysqldb
mysqladmin -u root password MYSQL_PASS

sed -i -e 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf


service mysql restart
mysql_install_db
mysql_secure_installation



export DEBIAN_FRONTEND=noninteractive

apt-get install -y ntp rabbitmq-server python-novaclient python-neutronclient
python-keystoneclient python-glanceclient python-swiftclient python-cinderclient python-heatclient
python-ceilometerclient 

rabbitmqctl change_password guest RABBIT_PASS
echo "clearing iptables"
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

mysql -u root -pMYSQL_PASS -e "SET GLOBAL max_connect_errors=10000;;"
mysql -u root -pMYSQL_PASS -e "FLUSH HOSTS;;"
restart mysql

echo "Installing Keystone"

apt-get install -y keystone
cp keystone/keystone.conf /etc/keystone/keystone.conf

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE keystone;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'MYSQL_PASS';"
mysql -u root -pMYSQL_PASS -e "FLUSH PRIVILEGES;"
keystone-manage db_sync

service keystone restart

sleep 2
export OS_SERVICE_TOKEN=ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0

keystone tenant-create --name=service --description="Service Tenant"
keystone tenant-create --name=admin --description="Admin Tenant"
keystone tenant-create --name=service --description="Service Tenant"
keystone user-create --name=admin --pass=ADMIN_PASS --email=admin@example.com
keystone role-create --name=admin
keystone user-role-add --user=admin --tenant=admin --role=admin

keystone service-create --name=keystone --type=identity --description="Keystone Identity Service"

service_id=$(keystone service-list | grep keystone |awk '{print $2}')
echo $service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:5000/v2.0 \
      --internalurl=http://controller:5000/v2.0 \
        --adminurl=http://controller:35357/v2.0 

        unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
        export OS_USERNAME=admin
        export OS_PASSWORD=ADMIN_PASS
        export OS_TENANT_NAME=admin
        export OS_AUTH_URL=http://controller:35357/v2.0

echo "verify Keystone:"

keystone user-list

echo "---------------------------------------------------------------------Keystone working, Enter to continue."




#Installs Glance
echo "Installing Glanceglance"
apt-get install -y glance python-glanceclient
cp glance/glance* /etc/glance
rm /var/lib/glance/glance.sqlite

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE glance;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql -u root -pMYSQL_PASS -e "FLUSH PRIVILEGES;"

glance-manage db_sync

keystone user-create --name=glance --pass=GLANCE_PASS --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin
keystone service-create --name=glance --type=image --description="Glance Image Service"

service_id=$(keystone service-list | grep glance |awk '{print $2}')
echo $service_id
keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:9292 \
      --internalurl=http://controller:9292 \
        --adminurl=http://controller:9292

service glance-registry restart
service glance-api restart

sleep 2
mkdir ~/images
wget -P ~/images http://cdn.download.cirros-cloud.net/0.3.1/cirros-0.3.1-x86_64-disk.img

glance image-create --name="CirrOS 0.3.1" --disk-format=qcow2 \
  --container-format=bare --is-public=true < ~/images/cirros-0.3.1-x86_64-disk.img

glance image-list

echo "---------------------------------------------------------------------Glance working, Enter to continue."




#Now install nova controller projects

sudo apt-get install -y nova-novncproxy novnc nova-api nova-ajax-console-proxy nova-cert nova-conductor nova-consoleauth nova-doc nova-scheduler python-novaclient

sudo apt-get install -y nova-network 

cp nova/nova.conf /etc/nova/
cp nova/api-paste.ini /etc/nova/


sed -i -e "s/MY_IP/$MY_IP/g" /etc/nova/nova.conf

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE nova;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"
mysql -u root -pMYSQL_PASS -e "FLUSH PRIVILEGES;"

nova-manage db sync

keystone user-create --name=nova --pass=NOVA_PASS --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin
keystone service-create --name=nova --type=compute \
  --description="Nova Compute service"

service_id=$(keystone service-list | grep nova |awk '{print $2}')
echo $service_id
keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:8774/v2/%\(tenant_id\)s \
      --internalurl=http://controller:8774/v2/%\(tenant_id\)s \
        --adminurl=http://controller:8774/v2/%\(tenant_id\)s

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service nova-network restart

sleep 2
nova network-create vmnet --fixed-range-v4=10.0.0.0/24 \
  --bridge-interface=br100 --multi-host=T


nova list
echo "---------------------------------------------------------------------Nova Controller working, Enter to continue."

#Dashboard
apt-get install -y memcached libapache2-mod-wsgi openstack-dashboard
apt-get remove --purge openstack-dashboard-ubuntu-theme -y
cp openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py

service apache2 restart
service memcached restart



#Block Storage

apt-get install -y cinder-api cinder-scheduler
cp cinder/cinder.conf /etc/cinder/cinder.conf
cp cinder/api-paste.conf /etc/cinder/api-paste.conf

mysql -u root -pMYSQL_PASS -e "CREATE DATABASE cinder;"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'CINDER_DBPASS';"
mysql -u root -pMYSQL_PASS -e "GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';"
mysql -u root -pMYSQL_PASS -e "FLUSH PRIVILEGES;"

cinder-manage db sync
keystone user-create --name=cinder --pass=CINDER_PASS --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin

keystone service-create --name=cinder --type=volume \
  --description="Cinder Volume Service"
service_id=$(keystone service-list | grep cinder |awk '{print $2}')
echo $service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:8776/v1/%\(tenant_id\)s \
      --internalurl=http://controller:8776/v1/%\(tenant_id\)s \
        --adminurl=http://controller:8776/v1/%\(tenant_id\)s

keystone service-create --name=cinderv2 --type=volumev2 \
  --description="Cinder Volume Service V2"

service_id=$(keystone service-list | grep cinderv2 |awk '{print $2}')
echo $service_id

keystone endpoint-create \
  --service-id=$service_id \
    --publicurl=http://controller:8776/v2/%\(tenant_id\)s \
      --internalurl=http://controller:8776/v2/%\(tenant_id\)s \
        --adminurl=http://controller:8776/v2/%\(tenant_id\)s

service cinder-scheduler restart
service cinder-api restart


# Telemetry - optional

read -r -p "Do you want to install OpenStack Telemetry? (ceilometer) [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
  apt-get install -y ceilometer-api ceilometer-collector ceilometer-agent-central python-ceilometerclient mongodb
    cp /mongodb/mongodb.conf /etc/
    sed -i -e "s/MY_IP/$MY_IP/g" /etc/mongodb.conf
    service mongodb restart

    mongo --host controller --eval '
      db = db.getSiblingDB("ceilometer");
      db.addressUser({user: "ceilometer",
            pwd: "CEILOMETER_DBPASS",
            roles: [ "readWrite", "dbAdmin" ]})'

    cp /ceilometer/ceilometer.conf /etc/ceilometer/ceilometer.conf
    
    keystone user-create --name=ceilometer --pass=CEILOMETER_PASS --email=ceilometer@example.com
    keystone user-role-add --user=ceilometer --tenant=service --role=admin

    keystone service-create --name=ceilometer --type=metering \
  --description="Ceilometer Telemetry Service"
     keystone endpoint-create \
  --service-id=$(keystone service-list | awk '/ metering / {print $2}') \
  --publicurl=http://controller:8777 \
  --internalurl=http://controller:8777 \
  --adminurl=http://controller:8777

  service ceilometer-agent-central restart
  service ceilometer-api restart
  service ceilometer-collector restart
else
    echo "Not installing Ceilometer..."





# This is where I got to, at the end, should output all the passwords

echo "Your mysql password is: MYSQL_PASS"
echo "Your Rabbit MQ guest password is: RABBIT_PASS"


echo "Your Admin password is: ADMIN_PASS"





