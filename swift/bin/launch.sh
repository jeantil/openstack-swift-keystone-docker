#!/bin/sh
service rsyslog start
service rsync start
service memcached start
# set up storage
#mkdir -p /swift/nodes/1
#ln -s /swift/nodes/1 /srv/1
#mkdir -p /srv/1/node/sdb1 /var/run/swift
#/usr/bin/sudo /bin/chown -R swift:swift /swift/nodes /etc/swift /var/run/swift /srv/1 
#/usr/bin/sudo -u swift /swift/bin/remakerings
service swift-proxy start
service swift-container start
service swift-account start
service swift-object start
apachectl -DFOREGROUND
