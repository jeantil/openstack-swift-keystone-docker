#!/bin/sh

service rsyslog start
service rsync start
service memcached start
service swift-proxy start
service swift-container start
service swift-account start
service swift-object start

if [ -z "$KS_SWIFT_PUBLIC_URL" ]; then
    echo "KS_SWIFT_PUBLIC_URL is required"
    exit 1
fi

CONFIG_PUB_URL=$(cat /opt/SWIFT_INIT)

if [ "$KS_SWIFT_PUBLIC_URL" = "$CONFIG_PUB_URL" ]; then
    echo "$KS_SWIFT_PUBLIC_URL endpoint already configured."
else
    echo "Configuring $KS_SWIFT_PUBLIC_URL endpoint."

    echo "Starting apache."
    apachectl start
    echo "Apache started."

    openstack endpoint create --region RegionOne object-store internal http://127.0.0.1:8080/v1/KEY_%\(tenant_id\)s
    openstack endpoint create --region RegionOne object-store admin http://127.0.0.1:8080/v1
    openstack endpoint create --region RegionOne object-store public ${KS_SWIFT_PUBLIC_URL}/v1/KEY_%\(tenant_id\)s

    echo "Stopping apache."
    apachectl stop
    echo "Apache stopped."

    echo "$KS_SWIFT_PUBLIC_URL" > /opt/SWIFT_INIT
fi

echo "Starting apache in foreground."

apachectl -DFOREGROUND
