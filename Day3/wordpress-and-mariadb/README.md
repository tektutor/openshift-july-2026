# Production WordPress + MariaDB on OpenShift

This set replaces the earlier demo. Three points shape it:

1. MariaDB runs as a GTID replicated cluster (one primary, N replicas), not
   three unrelated databases.
2. WordPress runs as a Deployment where every pod shares one `wp-content`
   volume, so uploads, plugins, and themes match across pods. It also gets an
   HPA, a PodDisruptionBudget, and a load-balanced Route.
3. No namespace is hardcoded. Every object deploys into your current project,
   so each trainee runs the same files in their own namespace. Switch project
   first with `oc project <your-namespace>`.

## Files, in apply order

The number prefix is the order `deploy.sh` applies them, so you can also apply
the whole set with `oc apply -f .` or step through them one at a time.

```
01-serviceaccount.yaml            ServiceAccount (gets anyuid in deploy.sh)
02-secrets.yaml                   Root, app, and replication credentials
03-nfs-config.yaml                NFS server and export paths (edit here)
04-mariadb-configmap.yaml         Common my.cnf for every node
05-mariadb-scripts-configmap.yaml Role bootstrap script
06-wordpress-configmap.yaml       WordPress DB host, name, user, prefix
07-pv-mariadb.yaml                NFS PV for the mariadb export path
08-pv-wordpress.yaml              NFS PV for the wordpress export path
09-pvc-mariadb.yaml               Claim bound to the mariadb PV
10-pvc-wordpress.yaml             Claim bound to the wordpress PV
11-mariadb-service.yaml           Headless service for stable pod DNS
12-mariadb-statefulset.yaml       MariaDB primary + replicas
13-mariadb-pdb.yaml               PodDisruptionBudget (minAvailable 2)
14-wordpress-service.yaml         ClusterIP service
15-wordpress-deployment.yaml      WordPress pods, shared wp-content
16-wordpress-route.yaml           External Route
17-wordpress-hpa.yaml             Autoscaler 3..6 on 70% CPU
18-wordpress-pdb.yaml             PodDisruptionBudget (minAvailable 2)
```

The MariaDB StatefulSet must finish rolling out before WordPress starts, so if
you apply files by hand, wait on `oc rollout status statefulset/mariadb`
between step 13 and step 14. `deploy.sh` already does this for you.

## Architecture

MariaDB StatefulSet, ordinal 0 is the primary and every higher ordinal is a
read-only GTID replica:

- An init container writes a unique `server_id` per pod and sets `read_only=ON`
  on replicas.
- A sidecar (`replication-bootstrap`) reads the pod ordinal and picks the role.
  Ordinal 0 creates the replication account and the WordPress database and user.
  Higher ordinals point `CHANGE MASTER` at `mariadb-0.mariadb` and start
  replicating with `MASTER_USE_GTID=slave_pos`. The sidecar is idempotent, so
  a restarted replica that already replicates does nothing.
- Each node keeps its own datadir under a per-pod NFS subpath.

WordPress talks to the primary at `mariadb-0.mariadb`, the short form that
resolves inside whatever namespace you deploy into. The replicas hold live
copies for standby and read scaling.

## Storage layout on NFS

```
/var/nfs/jegan/mysql/mariadb-0        <- primary datadir
/var/nfs/jegan/mysql/mariadb-1        <- replica datadir
/var/nfs/jegan/mysql/mariadb-2        <- replica datadir
/var/nfs/jegan/wordpress/wp-content   <- shared by every wordpress pod
```

MariaDB uses `subPathExpr: $(POD_NAME)`, so each node gets its own directory and
scaling needs no new PV. WordPress uses a fixed `subPath: wp-content` shared by
all pods.

The NFS server and both export paths live in `03-nfs-config.yaml`. A
PersistentVolume cannot read those fields from a ConfigMap, since the PV spec
has no `valueFrom`, so `deploy.sh` reads the ConfigMap and writes the values
into `07-pv-mariadb.yaml` and `08-pv-wordpress.yaml` before applying them. Edit
the ConfigMap, run `deploy.sh`, and the PVs follow. If you skip `deploy.sh` and
run `oc apply -f .`, the PVs use the literal values already in those two files,
which match the ConfigMap defaults (server `192.168.10.200`).

One caveat for a shared cluster: PVs are cluster-scoped, so the names
`mariadb-nfs-pv` and `wordpress-nfs-pv` and the export paths are global. If many
trainees share one cluster, give each a distinct PV name and NFS subpath.
On separate clusters, for example one CRC per trainee, the defaults are fine.

## Prerequisites

1. An NFS server at `192.168.10.200` exporting the two paths read-write with
   `no_root_squash`. Change the address or paths in `03-nfs-config.yaml`.
   ```
   /var/nfs/jegan  *(rw,sync,no_root_squash,no_subtree_check)
   ```
2. Cluster-admin, since deploy grants the `anyuid` SCC to the service account in
   your project. If trainees are not cluster-admin, the instructor runs
   `oc adm policy add-scc-to-user anyuid -z wp-mariadb-sa -n <namespace>` for each.
3. `oc` logged in and pointed at the target project (`oc project <namespace>`).
   HPA needs metrics, which OpenShift ships by default.

## Deploy

```bash
oc project my-namespace     # deploy lands wherever this points
./deploy.sh
```

The script reads the NFS settings from `03-nfs-config.yaml`, stamps them into the
PVs, applies everything into your current project, waits for the cluster, prints
replica status, and prints the WordPress URL. Finish the install wizard there.

## Verify replication by hand

```bash
oc exec mariadb-1 -c mariadb -- \
  bash -c 'mysql --socket=/run/mysqld/mysqld.sock -uroot -p"$MYSQL_ROOT_PASSWORD" \
  -e "SHOW SLAVE STATUS\G"' | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master"
```

Both `Slave_IO_Running` and `Slave_SQL_Running` should read `Yes`. Write a row
on the primary and read it back on a replica to confirm flow.

## Scaling

```bash
oc scale statefulset/mariadb   --replicas=5   # adds replicas 3 and 4
oc scale deployment/wordpress  --replicas=6   # HPA also scales 3..6
```

New MariaDB replicas attach and replicate from the primary. New WordPress pods
mount the same shared `wp-content`. Scaling down leaves NFS data in place because
the reclaim policy is `Retain`.

## Honest limitations, and how to close each one

Read these before calling this production for a real site.

1. No automatic failover. If `mariadb-0` dies, the StatefulSet restarts the same
   pod on the same NFS data, so it self-heals as primary, but writes pause during
   the restart. There is no automatic promotion of a replica. For real failover,
   move to the MariaDB Operator (Galera or replication mode with a controller) or
   put MaxScale in front. The operator handles primary election, backups, and
   bootstrap, which are the hard parts you would otherwise script.

2. Adding a replica long after heavy writes. A fresh replica replicates from the
   earliest retained binlog. If binlogs have rotated past the point where the
   database was empty, that replica cannot catch up from zero and needs a data
   seed first, for example a `mariabackup` restore from the primary. On a fresh
   cluster that starts together this is not an issue.

3. NFS under a database. NFS works for a demo and light load, but a busy MariaDB
   wants low-latency block storage (Ceph RBD, cloud block volumes). Keep the NFS
   layout for teaching and switch the datadir StorageClass for real workloads.

4. WordPress read scaling. Every WordPress pod writes to the single primary. To
   send reads to replicas, add ProxySQL or MaxScale and point WordPress at the
   proxy. WordPress core does not split reads on its own.

5. First-boot wp-content. The WordPress entrypoint copies default content into
   the shared volume on first start. Starting many pods at once can race on that
   copy. Roll out with one replica first, let it populate, then scale up. After
   that the shared content is stable.

6. anyuid. The upstream images run as a fixed UID, so this grants `anyuid`. For a
   non-root posture, swap MariaDB for `registry.redhat.io/rhel9/mariadb-1011`
   (runs under an arbitrary UID) and use a WordPress build that listens on 8080,
   then drop the SCC grant.

## Path to full production MariaDB

If you want the real thing rather than hand-managed replication, install the
MariaDB Operator and declare a Galera cluster:

```yaml
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: mariadb
spec:
  rootPasswordSecretKeyRef:
    name: mariadb-secret
    key: MYSQL_ROOT_PASSWORD
  replicas: 3
  galera:
    enabled: true
  storage:
    size: 20Gi
    storageClassName: <your-storage-class>
```

That gives you three writable nodes, synchronous replication, automatic state
transfer to new nodes, and failover, which the raw manifests here do not.
