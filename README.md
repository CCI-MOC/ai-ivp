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

* Node VLANs - Carry primary cluster traffic, host networking (br-ex), OVN-Kubernetes overlay, and control plane communication:
  * Infra VLAN
  * Staging VLAN
  * Production VLAN
  * Dev-Infra VLAN
  * Dev VLAN

* Storage VLANs - Dedicated networks for Pure FlashBlade traffic (PVCs and object storage):
  * Infra-Storage VLAN
  * Dev-Infra-Storage VLAN
  * Dev-Storage VLAN
  * Staging-Storage VLAN
  * Production-Storage VLAN

* iDRAC / BMC Network - A separate VLAN used by the Dell server hardware for a dedicated IP address per node that is used to manage the hardware. ACM connects to provision nodes via Redfish.

* Pod and Service networks - separate subnets used by the OVN-Kubernetes software defined network. Reachable only within an individual cluster.

All subnets are non-overlapping, except for the Pod and Service subnets. Pod and Service CIDRs may overlap between clusters but must not overlap with any host or enterprise networks.


#### Physical NIC Allocation

Current hardware has 2×10 GbE NICs. New hardware will have multiple 100 GbE NICs. The design accomodates current hardware while allowing us to mature the configuration as we procure new hardware and scale.

##### Initial Design (2x10 GbE NICs)

Each node will have two NICs:

* Primary NIC: Attached to the appropriate Node VLAN. Used for br-ex bridge, host networking, OVN-Kubernetes overlay traffic, and HCP control plane communication.
* Secondary NIC: Attached to the corresponding Storage VLAN and exposed to pods via Multus secondary networks using the Localnet topology. This isolates heavy, bursty storage I/O from the primary cluster network.

NICs are mapped to VLANs as described below:

| Node Type | Primary NIC | Secondary NIC | Purpose |
|-- |-- | --| -- |
| Infra | Infra VLAN | Infra-Storage VLAN | Central control plane + dedicated storage | 
| Staging Workers | Staging VLAN | Staging-Storage VLAN | Staging workloads + isolated storage |
| Production Workers | Production VLAN | Production-Storage VLAN | Production AI workloads + isolated storage |
| Dev-Infra | Dev-Infra VLAN |Infra-Dev-Storage VLAN | Sandbox infra + dedicated storage | 
| Dev Workers | Dev VLAN | Dev-Storage VLAN | Dev workloads + isolated storage |


**Note:** We are using Hosted Control Planes. Control plane traffic will be routed between the Infra and Staging/Production VLANs. The Staging/Production worker nodes will not have interfaces configured for the Infra VLAN. Likewise for Dev-Infra / Dev.


##### Future State (Multi-100 GbE Hardware)

When new hardware arrives, the design will evolve to:

* Use on NICs or bond multiple for the primary (br-ex) interface on Node VLANs.
* Continue using separate NICs/bonds for Storage VLANs
* Add dedicated NICs for a high-performance AI Fabric carried on one or more additional secondary networks.
* Leverage SR-IOV on select high-priority AI pods for maximum performance.

#### Security & Compliance

This design supports our compliance requirements:

* VLAN segmentation provides strong Layer 2/3 isolation required for HIPAA.
* Storage traffic is fully isolated on dedicated Storage VLANs and secondary networks.
* All inter-VLAN traffic will be controlled via firewall rules following least-privilege principles.
* NetworkPolicies and AdminNetworkPolicies will be applied at the cluster level to enforce pod-to-pod traffic controls within each environment.

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

