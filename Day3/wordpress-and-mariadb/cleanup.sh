#!/usr/bin/env bash
# Removes the stack from your CURRENT project, in reverse apply order.
# The cluster-scoped PVs are deleted too. NFS data is retained (reclaim Retain).
set -euo pipefail
echo ">> Cleaning up project: $(oc project -q)"
for f in 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01; do
  oc delete -f ${f}-*.yaml --ignore-not-found
done
echo "Objects deleted. NFS data under the export paths is kept."
