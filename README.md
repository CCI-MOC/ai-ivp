# AI-Infrastructure Validated Pattern

A validated pattern for deploying a scalable, compliant platform for AI research.

Infrastructure as code is included to deploy the pattern in a repeatable fashion.

# Architecture

## Deployment

## Option 1 - HCP

![Logical Deployment Diagram](/diagrams/architecture-diagrams-HCP_Logical_Deployment_Diagram.drawio.png)

## Option 2 - No HCP

![Logical Deployment Diagram](/diagrams/architecture-diagrams-Non-HCP_Logical_Deployment_Diagram.drawio.png)

## Networking

![Logical Network Diagram](/diagrams/architecture-diagrams-HCP_Logical_Network_Diagram.drawio.png)


# Installation

## Bastion Setup

1. Configure and secure access for administrative users to the bastion server following [these instructions](docs/README_BASTION_ADMINS.md).
2. Provision the bastion server with the utilities and configuration required to install the OpenShift Infra cluster and manage the environment. (TODO: add link after merge)

