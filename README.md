# AI-Infrastructure Validated Pattern

A validated pattern for deploying a scalable, compliant platform for AI research.

Infrastructure as code is included to deploy the pattern in a repeatable fashion.

# Architecture

## Deployment

These diagrams show the components of the system and how they are deployed. Active architectural discussions are considering two options.

## Option 1 - HCP

This option uses OpenShift Hosted Control Planes.

![Logical Deployment Diagram](/diagrams/architecture-diagrams-HCP_Logical_Deployment_Diagram.drawio.png)

## Networking

This network digram shows how clusters and users connect.

![Logical Network Diagram](/diagrams/architecture-diagrams-HCP_Logical_Network_Diagram.drawio.png)

## Automation

This solution uses AutoshiftV2 for infrastructure as code style automation.

See the [forked Autoshift documentation](/README_AUTOSHIFT.md) for details.

This repository includes code adapted from the [open source AutoshiftV2 project](https://github.com/auto-shift/autoshiftv2/).

# Installation

## Bastion Setup

1. Configure and secure access for administrative users to the bastion server following [these instructions](docs/README_BASTION_ADMINS.md).
2. Provision the bastion server with the utilities and configuration required to install the OpenShift Infra cluster and manage the environment. (TODO: add link after merge)

