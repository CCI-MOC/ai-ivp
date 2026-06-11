# AI-Infrastructure Validated Pattern

A validated pattern for deploying a scalable, compliant platform for AI research.

Infrastructure as code is included to deploy the pattern in a repeatable fashion.

# Architecture

## Deployment

This deployment diagram shows the components of the system and how they are deployed.

![Logical Deployment Diagram](/diagrams/architecture-diagrams-HCP_Logical_Deployment_Diagram.drawio.png)

## Networking

### Overview
The networking architecture for this OpenShift 4.21 + ACM 2.16 Hosted Control Planes (HCP) deployment uses VLAN-based segmentation on bare-metal infrastructure. The design provides strong isolation, performance for AI workloads, and supports HIPAA compliance requirements through logical and physical separation of traffic.

### Logical Network Segmentation

- **Node VLANs** — Carry primary cluster traffic, host networking (`br-ex`), OVN-Kubernetes overlay, and control plane communication:
  - Infra VLAN
  - Staging VLAN
  - Production VLAN
  - Dev-Infra VLAN
  - Dev VLAN

- **Storage VLANs** — Dedicated networks for Pure FlashBlade traffic (PVCs and object storage):
  - Infra-Storage VLAN
  - Staging-Storage VLAN
  - Production-Storage VLAN
  - Dev-Infra-Storage VLAN
  - Dev-Storage VLAN

- **iDRAC / BMC Network** — A dedicated, isolated VLAN used exclusively for server hardware management. Each node has a BMC IP on this network. The Infra and Infra-Dev clusters uses Redfish virtual media over this network to automate node provisioning.

- **Pod and Service Networks** — Separate subnets used by the OVN-Kubernetes software-defined networking layer. These are reachable only within an individual cluster.

All host (machine) subnets are non-overlapping. Pod and Service CIDRs may overlap between clusters but must not overlap with any host or enterprise networks.

#### Physical NIC Allocation

Current hardware has 2×10 GbE NICs per node. New hardware will have multiple 100 GbE NICs. The design works with current hardware while providing a clear path to scale.

##### Initial Design (2×10 GbE NICs)

![Initial VLAN Design ](/diagrams/architecture-diagrams-vlans.drawio.png)

Each node will have two NICs:

- **Primary NIC**: Attached to the appropriate **Node VLAN**. Used for the `br-ex` bridge, host networking, OVN-Kubernetes overlay traffic, and HCP control plane communication.
- **Secondary NIC**: Attached to the corresponding **Storage VLAN** and exposed to pods via Multus secondary networks using the Localnet topology. This isolates heavy, bursty storage I/O from the primary cluster network.

NIC mapping:

| Node Type          | Primary NIC              | Secondary NIC                |
|--------------------|--------------------------|------------------------------|
| Infra              | Infra VLAN               | Infra-Storage VLAN           |
| Staging Workers    | Staging VLAN             | Staging-Storage VLAN         |
| Production Workers | Production VLAN          | Production-Storage VLAN      |
| Dev-Infra          | Dev-Infra VLAN           | Dev-Infra-Storage VLAN       |
| Dev Workers        | Dev VLAN                 | Dev-Storage VLAN             |

**Note:** Because we are using Hosted Control Planes, control plane traffic is routed between the Infra (and Dev-Infra) VLANs and the worker VLANs. Worker nodes do **not** have interfaces on the Infra or Dev-Infra VLANs.

##### Future State (Multi-100 GbE Hardware)

When new hardware arrives, the design will evolve to:

- Use one or more NICs (with optional bonding) for the primary (`br-ex`) interface on Node VLANs.
- Continue using dedicated NICs (or bonded pairs) for Storage VLANs. Bonding can be leveraged in Production for additional throughput and availability.
- Add dedicated NICs or bonds for a high-performance **AI Fabric** (via additional secondary networks on the Production VLAN).
- Leverage SR-IOV on select high-priority AI pods for maximum performance where needed.

#### Security & Compliance

This design supports our compliance requirements:

- VLAN segmentation provides strong Layer 2/3 isolation required for HIPAA.
- Storage traffic is fully isolated on dedicated Storage VLANs and secondary networks.
- All inter-VLAN traffic will be controlled via firewall rules following least-privilege principles.
- **NetworkPolicies** and **AdminNetworkPolicies** will be applied at the cluster level to enforce pod-to-pod traffic controls within each environment.

### User Connectivity

This high level network digram shows how  users connect to clusters.

![Logical Network Diagram](/diagrams/architecture-diagrams-HCP_Logical_Network_Diagram.drawio.png)

## Automation

This solution uses AutoshiftV2 for infrastructure as code style automation.

See the [forked Autoshift documentation](/README_AUTOSHIFT.md) for details.

This repository includes code adapted from the [open source AutoshiftV2 project](https://github.com/auto-shift/autoshiftv2/).

# Installation

## Bastion Setup

1. Configure and secure access for administrative users to the bastion server following [these instructions](docs/README_BASTION_ADMINS.md).
2. Provision the bastion server with the utilities and configuration required to install the OpenShift Infra cluster and manage the environment. (TODO: add link after merge)

