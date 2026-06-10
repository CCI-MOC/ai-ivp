#!/bin/bash
set -euo pipefail

# Validate command line parameters
STORAGE_CLASS_NAME=$1
if [ -z "${STORAGE_CLASS_NAME}" ]; then
  echo "Usage: $0 <STORAGE_CLASS_NAME>"
  echo "Example: $0 gp3"
  exit 1
fi

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

# Official etcd-perf Test (recommended by Red Hat)
oc run etcd-perf-test \
  --image=quay.io/cloud-bulldozer/etcd-perf:latest \
  --restart=Never \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "etcd-perf",
      "image": "quay.io/cloud-bulldozer/etcd-perf:latest",
      "command": ["/bin/sh", "-c"],
      "args": [
        "mkdir -p /var/lib/etcd && \
         echo \"=== Running official etcd-perf test ===\" && \
         /usr/bin/run.sh"
      ],
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

echo "=== Waiting for test to complete ==="
oc wait --for=condition=PodScheduled pod/etcd-perf-test --timeout=120s
oc wait --for=jsonpath='{.status.phase}'=Succeeded pod/etcd-perf-test --timeout=900s || true

echo "=== Test Results ==="
oc logs etcd-perf-test

echo "=== Cleanup ==="
oc delete pod etcd-perf-test --ignore-not-found || true
oc delete pvc fio-test-pvc --ignore-not-found || true

