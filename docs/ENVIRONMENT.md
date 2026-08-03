# Machine Details

## Bastion

| Purpose             | Hostname             | IP         | iDRAC IP | Hardware | Notes                                                                                                           | 
| ------------------- | -------------------- | ---------- | ---------- | -------- | --------------------------------------------------------------------------------------------------------------- |
| Bastion             | mocsec-r4pac06u37-1b | 10.11.0.20 | TBD        | FC430    | Accessed via SSH and VNC. VNC is used to get a desktop with a browser for the iDRAC virtual console. | 

## Infra

| Purpose             | Hostname             | IP         | iDRAC IP   | Hardware | Notes | 
| ------------------- | -------------------- | ---------- | ---------- | -------- | ----- |
| Control / Worker    | mocsec-r4pac06u33-3a | 10.11.0.21 | 10.6.1.175 | FC430    | Boot drive serial: BTHC712204J1200QGN. Etcd drive WWN: 0x55cd2e414db91779 |
| Control / Worker    | mocsec-r4pac06u35-3a | 10.11.0.22 | 10.6.1.185 | FC430    | Boot drive serial: BTHC650104AJ200QGN. Etcd drive WWN: 0x55cd2e414d90b8ea |
| Control / Worker    | mocsec-r4pac06u37-3a | 10.11.0.23 | 10.6.1.195 | FC430    | Boot drive serial: BTHC70400116200QGN. Etcd drive WWN: 0x55cd2e414da035e8 |

**NOTE:** The boot drive is identified by serial number in `agent-config.yaml`'s `rootDeviceHints`. The etcd drive is identified by WWN via a `/dev/disk/by-id/wwn-<value>` path -- a separate mechanism, matched by hostname in a shell script rather than `rootDeviceHints`. Confirmed live via `lsblk`/`oc debug node` as of this writing.

**NOTE:** The full Ansible-consumable values for each cluster (MACs, IPs, storage devices, network config) live in `playbooks/group_vars/<cluster_name>/vars.yml` -- this table is a human-readable summary, not the source of truth for automation. Before wiping a cluster, see [Verifying group_vars against a live cluster](README_VERIFY_GROUP_VARS.md) to confirm those values against live state while you still can.

## Staging

| Purpose             | Hostname             | IP         | iDRAC IP   | Hardware | Notes | 
| ------------------- | -------------------- | ---------- | ---------- | -------- | ----- |
| Worker              |                      | 10.6.1.176 |            |          |       |
| Worker              |                      | 10.6.1.186 |            |          |       |
| Worker              |                      | 10.6.1.196 |            |          |       |

