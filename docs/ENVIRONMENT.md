# Machine Details

## Bastion

| Purpose             | Hostname             | IP         | iDRAC IP | Hardware | Notes                                                                                                           | 
| ------------------- | -------------------- | ---------- | ---------- | -------- | --------------------------------------------------------------------------------------------------------------- |
| Bastion             | mocsec-r4pac06u37-1b | 10.11.0.20 | TBD        | FC430    | Accessed via SSH and VNC. VNC is used to get a desktop with a browser for the iDRAC virtual console. | 

## Infra

| Purpose             | Hostname             | IP         | iDRAC IP   | Hardware | Notes | 
| ------------------- | -------------------- | ---------- | ---------- | -------- | ----- |
| Control / Worker    | mocsec-r4pac06u33-3a | 10.11.0.21 | 10.6.1.175 | FC430    | Storage device names: sda, sdb |
| Control / Worker    | mocsec-r4pac06u35-3a | 10.11.0.22 | 10.6.1.185 | FC430    | Storage device names: sdb, sdc |
| Control / Worker    | mocsec-r4pac06u37-3a | 10.11.0.23 | 10.6.1.195 | FC430    | Storage device names: sdb, sdc |

**NOTE:** The storage device names are not guaranteed to be stable. We should switch to using serial numbers. The names are included here for convenience.

## Staging

| Purpose             | Hostname             | IP         | iDRAC IP   | Hardware | Notes | 
| ------------------- | -------------------- | ---------- | ---------- | -------- | ----- |
| Worker              |                      | 10.6.1.176 |            |          |       |
| Worker              |                      | 10.6.1.186 |            |          |       |
| Worker              |                      | 10.6.1.196 |            |          |       |

