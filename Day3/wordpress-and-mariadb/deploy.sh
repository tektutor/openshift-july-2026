#!/usr/bin/env bash
# Deploy the production WordPress + MariaDB stack into your CURRENT project.
# No namespace is hardcoded; whatever `oc project` shows is where this lands.
#
# Edit NFS settings in 03-nfs-config.yaml. This script stamps those values
# into the two PV files before applying them, so the ConfigMap is the one
# place you change the NFS server or paths.
#
# Usage: ./deploy.sh
set -euo pipefail

NS="$(oc project -q)"
echo ">> Deploying into project: ${NS}"

# Read NFS settings from the ConfigMap file (not from an environment variable).
CFG=03-nfs-config.yaml
NFS_SERVER="$(awk -F'"' '/nfs-server:/{print $2}'        "$CFG")"
MDB_PATH="$(awk -F'"'  '/mariadb-nfs-path:/{print $2}'   "$CFG")"
WP_PATH="$(awk -F'"'   '/wordpress-nfs-path:/{print $2}' "$CFG")"
echo ">> NFS from ${CFG}: server=${NFS_SERVER} mariadb=${MDB_PATH} wordpress=${WP_PATH}"

# Stamp them into the PVs (replaces whatever server:/path: lines are there).
sed -i -E "s#(^[[:space:]]*server:).*#\1 ${NFS_SERVER}#" 07-pv-mariadb.yaml 08-pv-wordpress.yaml
sed -i -E "s#(^[[:space:]]*path:).*#\1 ${MDB_PATH}#"      07-pv-mariadb.yaml
sed -i -E "s#(^[[:space:]]*path:).*#\1 ${WP_PATH}#"       08-pv-wordpress.yaml

echo ">> 01 service account"
oc apply -f 01-serviceaccount.yaml

echo ">> Granting anyuid SCC to wp-mariadb-sa in ${NS} (needs cluster-admin)"
oc adm policy add-scc-to-user anyuid -z wp-mariadb-sa

echo ">> 02-06 config and secrets"
oc apply -f 02-secrets.yaml
oc apply -f 03-nfs-config.yaml
oc apply -f 04-mariadb-configmap.yaml
oc apply -f 05-mariadb-scripts-configmap.yaml
oc apply -f 06-wordpress-configmap.yaml

echo ">> 07-10 storage"
oc apply -f 07-pv-mariadb.yaml
oc apply -f 08-pv-wordpress.yaml
oc apply -f 09-pvc-mariadb.yaml
oc apply -f 10-pvc-wordpress.yaml

echo ">> 11-13 mariadb"
oc apply -f 11-mariadb-service.yaml
oc apply -f 12-mariadb-statefulset.yaml
oc apply -f 13-mariadb-pdb.yaml

echo ">> Waiting for the MariaDB cluster to form"
oc rollout status statefulset/mariadb --timeout=600s

echo ">> 14-18 wordpress"
oc apply -f 14-wordpress-service.yaml
oc apply -f 15-wordpress-deployment.yaml
oc apply -f 16-wordpress-route.yaml
oc apply -f 17-wordpress-hpa.yaml
oc apply -f 18-wordpress-pdb.yaml

oc rollout status deployment/wordpress --timeout=300s

echo ">> Replica status check:"
for i in 1 2; do
  echo "--- mariadb-$i ---"
  oc exec mariadb-$i -c mariadb -- \
    bash -c 'mysql --socket=/run/mysqld/mysqld.sock -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW SLAVE STATUS\G"' \
    2>/dev/null | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind" || true
done

echo ">> WordPress URL:"
echo "http://$(oc get route wordpress -o jsonpath='{.spec.host}')"
