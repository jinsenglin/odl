#!/bin/bash

set -e

LOG=/tmp/provision.log
date | tee $LOG            # when:  Thu Aug 10 07:48:13 UTC 2017
whoami | tee -a $LOG       # who:   root
pwd | tee -a $LOG          # where: /home/ubuntu

CACHE=/vagrant/cache
[ -d $CACHE ] || mkdir -p $CACHE 

function use_local_apt_server() {
    cat > /etc/apt/sources.list <<DATA
deb http://192.168.240.3/ubuntu xenial main restricted
deb http://192.168.240.3/ubuntu xenial universe
deb http://192.168.240.3/ubuntu xenial multiverse
deb http://192.168.240.3/ubuntu xenial-updates main restricted
deb http://192.168.240.3/ubuntu xenial-updates universe
deb http://192.168.240.3/ubuntu xenial-updates multiverse
deb http://192.168.240.3/ubuntu xenial-security main restricted
deb http://192.168.240.3/ubuntu xenial-security universe
deb http://192.168.240.3/ubuntu xenial-security multiverse
deb http://192.168.240.3/ubuntu-cloud-archive xenial-updates/newton main
DATA

    rm -rf /var/lib/apt/lists/*
    echo 'APT::Get::AllowUnauthenticated "true";' > /etc/apt/apt.conf.d/99-use-local-apt-server
    apt-get update && APT_UPDATED=true
}

function each_node_must_resolve_the_other_nodes_by_name_in_addition_to_IP_address() {
    cat >> /etc/hosts <<DATA
172.18.161.101 os-controller
172.18.161.102 os-network
172.18.161.103 os-compute
172.18.161.104 odl-controller
DATA

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-networking.html
}

function install_python() {
    PYTHON_VERSION=2.7.11-1
    PYTHON_PIP_VERSION=8.1.1-2ubuntu0.4
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y python=$PYTHON_VERSION python-pip=$PYTHON_PIP_VERSION
}

function install_ntp() {
    CHRONY_VERSION=2.1.1-1
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y chrony=$CHRONY_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # To enable other nodes to connect
    echo "allow 172.18.161.0/24" >> /etc/chrony/chrony.conf

    # Restart the NTP service
    service chrony restart

    # Verify operation
    chronyc sources

    # Log files
    # /var/log/chrony/measurements.log
    # /var/log/chrony/statistics.log
    # /var/log/chrony/tracking.log

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-ntp-controller.html
}

function install_sqldb() {
    MARIADB_SERVER_VERSION=10.0.31-0ubuntu0.16.04.2
    PYTHON_PYMSQL_VERSION=0.7.2-1ubuntu1
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y mariadb-server=$MARIADB_SERVER_VERSION python-pymysql=$PYTHON_PYMSQL_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Create and edit the /etc/mysql/mariadb.conf.d/99-openstack.cnf file
    # For development convenience, you can use 0.0.0.0 instead of the management IP address.
    cat > /etc/mysql/mariadb.conf.d/99-openstack.cnf <<DATA
[mysqld]
bind-address = 172.18.161.101

default-storage-engine = innodb
innodb_file_per_table
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
DATA

    # Restart the database service
    service mysql restart

    # Secure the database service by running the mysql_secure_installation script
    # skipped (root@localhost with no password by default)

    # Log files
    # /var/log/mysql/error.log

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-sql-database.html
}

function install_mq() {
    RABBITMQ_SERVER_VERSION=3.5.7-1ubuntu0.16.04.2
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y rabbitmq-server=$RABBITMQ_SERVER_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Add the openstack user
    rabbitmqctl add_user openstack RABBIT_PASS

    # Permit configuration, write, and read access for the openstack user
    rabbitmqctl set_permissions openstack ".*" ".*" ".*"

    # Log files
    # /var/log/rabbitmq/rabbit@ubuntu-xenial.log
    # /var/log/rabbitmq/rabbit@ubuntu-xenial-sasl.log
    # /var/log/rabbitmq/startup_err
    # /var/log/rabbitmq/startup_log

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-messaging.html
}

function install_memcached() {
    MEMCACHED_VERSION=1.4.25-2ubuntu1.2
    PYTHON_MEMCACHE_VERSION=1.57-1
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y memcached=$MEMCACHED_VERSION python-memcache=$PYTHON_MEMCACHE_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Edit the /etc/memcached.conf file and configure the service to use the management IP address of the controller node.
    # For development convenience, you can use 0.0.0.0 instead of the management IP address.
    sed -i "s/-l 127.0.0.1/-l 172.18.161.101/" /etc/memcached.conf

    # Restart the Memcached service
    service memcached restart

    # Log files
    # n/a

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/environment-memcached.html
}

function install_openstack_cli() {
    PYTHON_OPENSTACKCLIENT_VERSION=3.2.0-0ubuntu2~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt install -y python-openstackclient=$PYTHON_OPENSTACKCLIENT_VERSION

    cat > /root/admin-openrc <<DATA
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://os-controller:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
DATA

    cat > /root/demo-openrc <<DATA
export OS_USERNAME=demo
export OS_PASSWORD=DEMO_PASS
export OS_PROJECT_NAME=demo
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://os-controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
DATA

}

function install_keystone() {
    KEYSTONE_VERSION=2:10.0.2-0ubuntu1~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y keystone=$KEYSTONE_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Create the database
    mysql <<DATA
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';
DATA

    # Edit the /etc/keystone/keystone.conf file
    sed -i "s|^#provider = uuid|provider = fernet|" /etc/keystone/keystone.conf
    sed -i "s|^connection = sqlite.*|connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@os-controller/keystone|" /etc/keystone/keystone.conf

    # Populate the database
    su -s /bin/sh -c "keystone-manage db_sync" keystone

    # Initialize Fernet key repositories
    keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
    keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

    # Bootstrap the Identity service
    keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
                              --bootstrap-admin-url http://os-controller:35357/v3/ \
                              --bootstrap-internal-url http://os-controller:35357/v3/ \
                              --bootstrap-public-url http://os-controller:5000/v3/ \
                              --bootstrap-region-id RegionOne

    # Edit the /etc/apache2/apache2.conf file and configure the ServerName option to reference the controller node
    echo "ServerName os-controller" >> /etc/apache2/apache2.conf 

    # Restart the Apache service
    service apache2 restart

    # Remove the default SQLite database
    rm -f /var/lib/keystone/keystone.db

    # Now can use admin token
    source /root/admin-openrc
    openstack token issue

    # Now can use admin token to create more domains, projects, users, and roles
    openstack project create --domain default --description "Service Project" service
    openstack project create --domain default --description "Demo Project" demo
    openstack user create --domain default --password DEMO_PASS demo
    openstack role create user
    openstack role add --project demo --user demo user

    # For security reasons, disable the temporary authentication token mechanism
    # Edit the /etc/keystone/keystone-paste.ini file and remove admin_token_auth from the [pipeline:public_api], [pipeline:admin_api], and [pipeline:api_v3] sections.
    # skipped

    # Log files
    # /var/log/keystone/keystone-manage.log
    # /var/log/apache2/keystone_access.log
    # /var/log/apache2/keystone.log

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/keystone.html
}

function install_glance() {
    GLANCE_VERSION=2:13.0.0-0ubuntu1~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y glance=$GLANCE_VERSION

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # Create the database
    mysql <<DATA
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';
DATA

    # Create the user
    source /root/admin-openrc
    openstack user create --domain default --password GLANCE_PASS glance

    # Associate the user with the admin role and the service project
    source /root/admin-openrc
    openstack role add --project service --user glance admin

    # Create the service entity
    source /root/admin-openrc
    openstack service create --name glance --description "OpenStack Image" image

    # Create the service api endpoint
    source /root/admin-openrc
    openstack endpoint create --region RegionOne image public http://os-controller:9292
    openstack endpoint create --region RegionOne image internal http://os-controller:9292
    openstack endpoint create --region RegionOne image admin http://os-controller:9292

    # Edit the /etc/glance/glance-api.conf file
    # TODO

    # Edit the /etc/glance/glance-registry.conf file
    # TODO

    # Populate the database
    su -s /bin/sh -c "glance-manage db_sync" glance

    # Restart the Image services
    service glance-registry restart
    service glance-api restart

    # LOG files
    # /var/log/glance/glance-api.log
    # /var/log/glance/glance-registry.log    

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/glance.html
}

function install_neutron() {
    NEUTRON_SERVER_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    NEUTRON_PLUGIN_ML2_VERSION=2:9.4.0-0ubuntu1.1~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt install -y neutron-server=$NEUTRON_SERVER_VERSION \
                   neutron-plugin-ml2=$NEUTRON_PLUGIN_ML2_VERSION

    # TODO
    # ?

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/neutron-controller-install-option2.html
    # This reference uses neutron-linuxbridge-agent, but we need neutron-openvswitch-agent.
    # This reference is for 2-nodes deployment (one controller, one compute), but we need 3-nodes deployment (one controller, one network, one compute).

    # Reference https://docs.openstack.org/neutron/pike/admin/deploy-ovs-selfservice.html
    # This reference is for pike version, but we need newton version.
    # This reference uses neutron-openvswitch-agent.
    # This reference is for VXLAN self-service networks.
    # This reference is for 3-nodes deployment.

    # Reference http://www.unixarena.com/2015/10/openstack-configure-network-service-neutron-controller-part-6.html
    # Reference http://www.unixarena.com/2015/10/openstack-configure-neutron-on-network-node-part-7.html
    # Reference http://www.unixarena.com/2015/10/openstack-configure-neutron-on-compute-node-part-8.html
    # This reference is for 3-nodes deployment.
    # `apt-get install neutron-server neutron-plugin-ml2` # for controller node
    # `apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent` # for network node
    # `apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent` # for compute node
}

function install_nova() {
    NOVA_API_VERSION=2:14.0.7-0ubuntu2~cloud0
    NOVA_CONDUCTOR_VERSION=2:14.0.7-0ubuntu2~cloud0
    NOVA_CONSOLEAUTH_VERSION=2:14.0.7-0ubuntu2~cloud0
    NOVA_NOVNCPROXY_VERSION=2:14.0.7-0ubuntu2~cloud0
    NOVA_SCHEDULER_VERSION=2:14.0.7-0ubuntu2~cloud0
    [ "$APT_UPDATED" == "true" ] || apt-get update && APT_UPDATED=true
    apt-get install -y nova-api=$NOVA_API_VERSION nova-conductor=$NOVA_CONDUCTOR_VERSION nova-consoleauth=$NOVA_CONSOLEAUTH_VERSION nova-novncproxy=$NOVA_NOVNCPROXY_VERSION nova-scheduler=$NOVA_SCHEDULER_VERSION

    # TODO
    # ?

    # Reference https://docs.openstack.org/newton/install-guide-ubuntu/nova.html
}

function main() {
    :
    use_local_apt_server
    each_node_must_resolve_the_other_nodes_by_name_in_addition_to_IP_address
    install_python
    install_ntp
    install_sqldb
    install_mq
    install_memcached
    install_openstack_cli
    install_keystone
    install_glance
    install_neutron
    install_nova
}
main
