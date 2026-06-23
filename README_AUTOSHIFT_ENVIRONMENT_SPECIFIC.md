# Additional AutoShift Local Environment Considerations

This guide contains a description of customizations made to base AutoShift relevant to the MOC infra cluster. Installation and basic familiarization information regarding AutoShift can be found in the `README_AUTOSHIFT.md` and `docs/quickstart.md` files.

## autoshift-install.yaml

This OpenShift resource contains basic definitions for configuring the autoshift application that is managed in ArgoCD.

*spec.source.helm.valueFiles*: The file used to create the spec for the hub cluster has been changed to `autoshift/values/clustersets/hub-minimal.yaml`

> [!NOTE]
> Ensure that this key contains the correct files. If the `autoshift/values/clustersets/hub.yaml` file is mistakenly applied the hub cluster will install extra operators not necessary for cluster operation.

## autoshift/values/clustersets/hub-minimal.yaml

 This file contains specific label information to apply the correct set of operators to the hub cluster.

 Each operator's basic subscription information is configured here.

 ## polices/stable/\*

 These directories contain the configurations for each operator AutoShift is installing.

 - *Chart.yaml* - Helm chart for installation, no modification necessary
 - *values.yaml* - Values files for associated templates
 - *templates/* - This directory contains any templates for ACM policies as well as operator specific resources that will be deployed with the operator.

 The following environment specific changes have been made to these subdirectories:

 #### local-storage

 `templates/policy-local-volume-set.yaml` - Line 23-52 defines the LocalVolumeSet object that allows the operator to discover disks.

 ### nmstate

 `Values.yaml` - Lines 10-18 contain the basic configuration for the storage vlan NNCP for the infra cluster

 `/templates/policy-nmstate-nodenetworkconfigurationpolicy.yaml` - Lines 101-102 add the auto-gateway and auto-route configuration to the NNCP based on the values passed in from Values.yaml

 #### openshift-compliance-operator

 `templates/policy-nist-scan.yaml` - This template replaces the default STIG template with a configuration to enable NIST 800 based scanning. Additional scans can be added/removed under the profiles definitions in lines 103-113.

 ## Additional Secrets

 Until a secret management solution can be finalized, the following secrets will need to be manually created to allow this configuration to function:

*For Github IDP*
```bash
oc create secret generic github-client-secret --from-literal=clientSecret=<YOUR_GITHUB_CLIENT_SECRET> -n openshift-config
```

After someone logs in their username will be automatically created. It will be the same as their github username. From there give them correct role for acces, ie for Cluster-Admin running
```bash
oc adm policy add-cluster-role-to-user cluster-admin <your-github-username>
```

*For HTTPS*
```bash
oc create secret generic aws-route53-credentials --from-literal=secret-access-key="YOUR_AWS_SECRET_ACCESS_KEY" -n cert-manager
```

*For Portworx*
```bash
oc create secret generic px-pure-secret --from-file=pure.json=<file path> --namespace portworx
```