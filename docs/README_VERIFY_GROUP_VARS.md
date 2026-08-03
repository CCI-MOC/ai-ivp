# Verifying group_vars against a live cluster

Before wiping/reinstalling a cluster, it's worth double-checking that `playbooks/group_vars/<cluster_name>/vars.yml` actually matches the live system, since some of these values may have been captured from documentation rather than confirmed directly, and you lose the ability to check once the nodes are wiped.

Run these against the currently-installed cluster (replace `<hostname>`, `<cluster>`, `<domain>`, `<dns_ip>` for your environment).

## MAC address (`master{N}_mac`)

```bash
oc debug node/<hostname> -- chroot /host ip -4 addr show
oc debug node/<hostname> -- chroot /host cat /sys/class/net/eno1/address
```

Run the first command before trusting the second — interface naming isn't guaranteed to be `eno1` on every node, so confirm it's actually the interface holding the node's known IP first.

## Storage devices -- boot vs. etcd drive (`master{N}_install_drive_serial` / `master{N}_etcd_drive`)

```bash
oc debug node/<hostname> -- chroot /host lsblk -b -o NAME,SIZE,TYPE,RM,MOUNTPOINT,SERIAL,WWN
```

Use `-b` for exact byte counts -- human-readable units (`186.3G` vs `0B`) are easy to misread in a wrapped terminal paste, which previously produced a false "missing hardware" conclusion for one node.

`master{N}_install_drive_serial` is the `SERIAL` of whichever disk has the boot partitions mounted (`/`, `/boot`). `master{N}_etcd_drive` is still device-name based (a separate mechanism, matched by hostname in `98-master-var-lib-etcd.j2`) -- use the device name of the other real disk.

## Gateway (`gateway_ip`)

```bash
oc debug node/<hostname> -- chroot /host ip route show default
```

## DNS resolver (`dns_ip`)

```bash
oc debug node/<hostname> -- chroot /host cat /etc/resolv.conf
```

Note the first entry is just the node's own IP, automatically generated. Compare against the *next* entry.

## NTP (`ntp`)

```bash
oc debug node/<hostname> -- chroot /host chronyc sources
```

A source marked `^x` is a "falseticker" -- excluded from actual time sync, not necessarily breaking anything if other sources are healthy, but worth knowing if the configured value isn't really functioning.

## Cluster/service network CIDRs (`cluster_network` / `svc_network`)

Cluster-level API object, not per-node:

```bash
oc get network.config cluster -o yaml
```

## API/API-int/console VIPs against real DNS (`api_ip` / `ingress_ip`)

Run from the bastion. `dig` bypasses `/etc/hosts` entirely (unlike `curl`/`ping`/`getent hosts`), so it reflects real DNS regardless of any custom `/etc/hosts` MachineConfig on the nodes:

```bash
for h in api.<cluster>.<domain> api-int.<cluster>.<domain> console-openshift-console.apps.<cluster>.<domain>; do
  echo -n "$h -> "
  dig @<dns_ip> "$h" +short
  echo
done
```

`api-int` returning no record from the bastion is normal. It's internal-only and not published in general DNS. Included here for completeness.
