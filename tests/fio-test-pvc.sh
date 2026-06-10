#!/bin/bash
set -euo pipefail

# Validate command line parameters
STORAGE_CLASS_NAME=$1
if [ -z "${STORAGE_CLASS_NAME}" ]; then
  echo "Usage: $0 <STORAGE_CLASS_NAME>"
  echo "Example: $0 gp3"
  exit 1
fi

echo "=== Deleting old PVC if it exists ==="
oc delete pvc fio-test-pvc --ignore-not-found --grace-period=0 --force || true

echo "=== Creating fresh PVC ==="
oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fio-test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: ${STORAGE_CLASS_NAME}
EOF

# =============================================
# Official etcd-perf Test (Red Hat recommended)
# =============================================
echo "=== Running Official etcd-perf Test ==="
oc run etcd-perf-test \
  --image=quay.io/cloud-bulldozer/etcd-perf:latest \
  --restart=Never \
  --overrides='{
  "spec": {
    "containers": [{
      "name": "etcd-perf",
      "image": "quay.io/cloud-bulldozer/etcd-perf:latest",
      "securityContext": {
        "runAsUser": 0,
        "runAsNonRoot": false
      },
      "volumeMounts": [{
        "mountPath": "/var/lib/etcd",
        "name": "test-volume"
      }]
    }],
    "securityContext": {
      "fsGroup": 0
    },
    "volumes": [{
      "name": "test-volume",
      "persistentVolumeClaim": {
        "claimName": "fio-test-pvc"
      }
    }]
  }
}'

echo "=== Following logs live (Ctrl+C stops watching, test continues) ==="
oc logs -f etcd-perf-test || true

echo "=== Waiting for test to finish (max 15 minutes) ==="
oc wait --for=jsonpath='{.status.phase}'=Succeeded pod/etcd-perf-test --timeout=900s || true

echo "=== Final Test Results ==="
oc logs etcd-perf-test

echo "=== Cleanup ==="
oc delete pod etcd-perf-test --ignore-not-found || true
oc delete pvc fio-test-pvc --ignore-not-found || true
