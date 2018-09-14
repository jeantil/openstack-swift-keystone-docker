# Pull base image.
FROM ubuntu:16.04

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update ;\
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y software-properties-common python-software-properties && \
    add-apt-repository -y cloud-archive:pike && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y keystone apache2 libapache2-mod-wsgi openstack

# Setup Keystone
RUN su -s /bin/sh -c "keystone-manage db_sync" keystone && \
    keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone && \
    keystone-manage credential_setup --keystone-user keystone --keystone-group keystone && \
    keystone-manage bootstrap --bootstrap-password 7a04a385b907caca141f \
        --bootstrap-admin-url http://127.0.0.1:35357/v3/ \
        --bootstrap-internal-url http://127.0.0.1:5000/v3/ \
        --bootstrap-public-url http://127.0.0.1:5000/v3/ \
        --bootstrap-region-id RegionOne && \
    export OS_USERNAME=admin && \
    export OS_PASSWORD=7a04a385b907caca141f && \
    export OS_PROJECT_NAME=admin && \
    export OS_USER_DOMAIN_NAME=Default && \
    export OS_PROJECT_DOMAIN_NAME=Default && \
    export OS_AUTH_URL=http://127.0.0.1:35357/v3 && \
    export OS_IDENTITY_API_VERSION=3 && \
    sed 's/# Global configuration/# Global configuration\nServerName keystone/g' -i etc/apache2/apache2.conf && \
    apachectl start && \
    openstack project create --domain default --description "Service Project" service && \
    openstack project create --domain default --description "Test Project" test && \
    openstack user create --domain default --password demo demo && \
    openstack role create user && \
    openstack role add --project test --user demo user

# Setup Swift
RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install -y swift swift-proxy swift-account swift-container swift-object\
    python-swiftclient python-keystoneclient python-keystonemiddleware memcached xfsprogs rsync sudo && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y curl httpie jq

# Setup Swift storage
RUN `#truncate -s 64MB /srv/swift-disk` && \
    `#mkfs.xfs /srv/swift-disk` && \
    `#echo '/srv/swift-disk /mnt/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0'>>/etc/fstab ` && \
    mkdir /mnt/sdb1 && \
    `#mount /mnt/sdb1 &&` \
    mkdir /mnt/sdb1/1 && \
    chown swift:swift /mnt/sdb1/* && \
    ln -s /mnt/sdb1/1 /srv/1 && \
    mkdir -p /srv/1/node/sdb1 /srv/1/node/sdb5 /var/run/swift && \
    chown -R swift:swift /var/run/swift && \
    chown -R swift:swift /srv/1/

COPY /etc/*.conf /etc/
COPY /etc/swift/ /etc/swift/
COPY /etc/rsyslog.d/ /etc/rsyslog.d/
COPY /swift/bashrc /swift/
COPY /swift/bin/* /swift/bin/

RUN export OS_USERNAME=admin && \
    export OS_PASSWORD=7a04a385b907caca141f && \
    export OS_PROJECT_NAME=admin && \
    export OS_USER_DOMAIN_NAME=Default && \
    export OS_PROJECT_DOMAIN_NAME=Default && \    
    export OS_AUTH_URL=http://127.0.0.1:35357/v3 && \
    export OS_IDENTITY_API_VERSION=3 && \
    apachectl start && \
    openstack user create --domain default --password fingertips swift && \
    openstack role add --project service --user swift admin && \
    openstack service create --name swift --description "OpenStack Object Storage" object-store && \
    sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync && \
    chmod -R +x /swift/bin/ && \
    mkdir -p /swift/nodes && \
    mkdir -p /var/log/swift && \
    mkdir -p /var/run/swift && \
    sed -i 's/\$PrivDropToGroup syslog/\$PrivDropToGroup adm/' /etc/rsyslog.conf && \
    mkdir -p /var/log/swift/hourly && \
    chown -R syslog.adm /var/log/swift && \
    chmod -R g+w /var/log/swift && \
    echo swift:fingertips | chpasswd && \
    usermod -a -G sudo swift && \
    echo %sudo ALL=NOPASSWD: ALL >> /etc/sudoers && \
    ln -s /swift/nodes/1 /srv/1 && \
    chown -R swift:swift /swift/nodes /etc/swift && \
    sudo -u swift /swift/bin/remakerings

ENV OS_USERNAME=admin
ENV OS_PASSWORD=7a04a385b907caca141f
ENV OS_PROJECT_NAME=admin
ENV OS_USER_DOMAIN_NAME=Default
ENV OS_PROJECT_DOMAIN_NAME=Default
ENV OS_AUTH_URL=http://127.0.0.1:35357/v3
ENV OS_IDENTITY_API_VERSION=3

EXPOSE 35357
EXPOSE 5000

CMD ["/swift/bin/launch.sh"]
