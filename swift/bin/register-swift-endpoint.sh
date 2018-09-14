#!/bin/sh

if [ -z "$1" ]; then
    echo "KS_SWIFT_PUBLIC_URL is a mandatory first argument."
    exit 1
else
  KS_SWIFT_PUBLIC_URL=$1
fi

openstack endpoint create --region RegionOne object-store internal http://127.0.0.1:8080/v1/KEY_%\(tenant_id\)s
openstack endpoint create --region RegionOne object-store admin http://127.0.0.1:8080/v1
openstack endpoint create --region RegionOne object-store public ${KS_SWIFT_PUBLIC_URL}/v1/KEY_%\(tenant_id\)s