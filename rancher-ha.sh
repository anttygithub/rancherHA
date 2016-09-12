#!/bin/sh
set -e
umask 077

IMAGE=$1
if [ "$IMAGE" = "" ]; then
    IMAGE=rancher/server
fi

mkdir -p /var/lib/rancher/etc/server
mkdir -p /var/lib/rancher/etc/ssl
mkdir -p /var/lib/rancher/bin

echo Creating /var/lib/rancher/etc/server.conf
cat > /var/lib/rancher/etc/server.conf << EOF
export CATTLE_HA_CLUSTER_SIZE=3
export CATTLE_HA_HOST_REGISTRATION_URL=https://172.16.1.82
export CATTLE_HA_CONTAINER_PREFIX=rancher-ha-

export CATTLE_DB_CATTLE_MYSQL_HOST=172.16.1.87
export CATTLE_DB_CATTLE_MYSQL_PORT=3306
export CATTLE_DB_CATTLE_MYSQL_NAME=cattle
export CATTLE_DB_CATTLE_USERNAME=admin
export CATTLE_DB_CATTLE_PASSWORD=86d14bf17c224103062bb97f27da2d2a:2b5b05b3ece489881d9691c88be0eebd

export CATTLE_HA_PORT_REDIS=6379
export CATTLE_HA_PORT_SWARM=2376
export CATTLE_HA_PORT_HTTP=80
export CATTLE_HA_PORT_HTTPS=443
export CATTLE_HA_PORT_PP_HTTP=81
export CATTLE_HA_PORT_PP_HTTPS=444
export CATTLE_HA_PORT_ZK_CLIENT=2181
export CATTLE_HA_PORT_ZK_QUORUM=2888
export CATTLE_HA_PORT_ZK_LEADER=3888

# Uncomment below to force HA enabled and not require one to set it in the UI
# export CATTLE_HA_ENABLED=true
EOF




echo Creating /var/lib/rancher/etc/server/encryption.key
if [ -e /var/lib/rancher/etc/server/encryption.key ]; then
    mv /var/lib/rancher/etc/server/encryption.key /var/lib/rancher/etc/server/encryption.key.`date '+%s'`
fi
cat > /var/lib/rancher/etc/server/encryption.key << EOF
u406yVpL1GWGRyF8kBUaE2DDSgYTuujnNP+5/ndysrA=
EOF


echo Creating /var/lib/rancher/bin/rancher-ha-start.sh
cat > /var/lib/rancher/bin/rancher-ha-start.sh << "EOF"
#!/bin/sh
set -e

IMAGE=$1
if [ "$IMAGE" = "" ]; then
    echo Usage: $0 DOCKER_IMAGE
    exit 1
fi

docker rm -fv rancher-ha >/dev/null 2>&1 || true
ID=`docker run --restart=always -d -v /var/run/docker.sock:/var/run/docker.sock --name rancher-ha --net host --privileged -v /var/lib/rancher/etc:/var/lib/rancher/etc $IMAGE ha`

echo Started container rancher-ha $ID
echo Run the below to see the logs
echo
echo docker logs -f rancher-ha
EOF

chmod +x /var/lib/rancher/bin/rancher-ha-start.sh

echo Running: /var/lib/rancher/bin/rancher-ha-start.sh $IMAGE
echo To re-run please execute: /var/lib/rancher/bin/rancher-ha-start.sh $IMAGE
exec /var/lib/rancher/bin/rancher-ha-start.sh $IMAGE
