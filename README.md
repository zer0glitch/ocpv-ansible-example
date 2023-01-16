# ocpv-ansible-example

## Introduction:
This is a project to provide examples for the [zer0glitch.ocpv](https://github.com/zer0glitch/ocpv) ansible collection.
- Install OpenShift Virtualization + Hyper-Converged
- Create nework policies
- Create virtual machines

### Assumptions:
In order to begin this course we have to assume you have met the below requirements:
- You have access to a workstation with an internet connection (I sure hope you do if you're reading this!)
- You have access to RHPDS.

### 1. Lab configuration - This step can be skipped when utilizing  a different instance of OCP 
#### Order your virtual environment rhpds
* Go to https://demo.redhat.com
* Search for "Virtualization"
* Select Hands on with Openshift Virutalization
* Order
* ssh to the server following creds
* Configure the demo enviornment 
```
sudo dnf install vim git -y
git clone https://github.com/zer0glitch/ocpv-ansible-example.git
cd ocpv-ansible-example/
./config.sh
```

#### CNV Installation via Ansible (Autmmated Install)

  * Install Operator and Hyper-converged 
  * [OCP Virtualization install role](https://github.com/zer0glitch/ocpv/blob/main/roles/install/tasks/main.yml)

```
---
- name: Install openshift virtualization
  hosts: localhost
  tasks:

  - name: import deploy_cnv
    import_role:
            name: zer0glitch.ocpv.install
```

  * `ansible-playbook -vv deploy-cnv.yaml`
  * Navigate to Operators-->Installed Operators
  * Select "Openshift Virtualization"
  * Select "All Instances"
  * You will see the install completed successfully

#### Configure a bridged network [Network configuratoin](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.11/html/openshift_virtualization/node-networking)
  * get the NodeNetworkState
  * `oc get nns`
  ```
   NAME       AGE
   master-0   68m
   master-1   68m
   master-2   68m
   worker-0   68m
   worker-1   68m
   worker-2   68m
  ```

  * look at the first worker node to see what interfaces are available, and which one we would like to bridge
  * `oc get nns -oyaml worker-0`
  ```
  apiVersion: nmstate.io/v1beta1
  kind: NodeNetworkState
  status:
      interfaces:
  ...
      - ipv4:
          address:
          - ip: 192.168.3.105
            prefix-length: 24
          auto-dns: true
          auto-gateway: true
          auto-route-table-id: 0
          auto-routes: true
          dhcp: true
          enabled: true
        ipv6:
          address:
  ...
      mac-address: DE:AD:BE:EF:02:50
      mtu: 8942
      name: ens5
      state: up
      type: ethernet

  ```
  * Create a bridge for ens5 with dhcp
   ```
   ---
   apiVersion: nmstate.io/v1
   kind: NodeNetworkConfigurationPolicy
   metadata:
     name: br1-ens5-policy
   spec:
     nodeSelector:
             node-role.kubernetes.io/worker: ""
     desiredState:
       interfaces:
         - name: br1
           description: Linux bridge with ens5 as a port
           type: linux-bridge
           state: up
           ipv4:
             enabled: false
           bridge:
             options:
               stp:
                 enabled: false
             port:
               - name: ens5
   ```

#### Creating a Virtual Machine with ansible (Autmmated Install)
  * Create a virtual machine
  * The role will use a virtual machine jinja2 [template](https://github.com/zer0glitch/ocpv/blob/main/roles/create_vm/templates/vm-template.yaml.j2)
  * The template offers benefits over just a standard openshift VM template, by using Ansible variables, the template can be customized quickly.

    * Run `ansible-playbook -vv create-vms.yaml` to create a virtual machine
    * Run `oc get vms --all-namespaces` or go to the UI and select *Virtual Machines* in the menu

#### Creating a Virtual Machine with ansible and configure a web server (Autmmated Install)
   * Look at the [setup-web-server.yml playbook](https://github.com/zer0glitch/ocpv-ansible-example/blob/main/standup-web-server.yml)
   * Run the following playbook `ansible-playbook -vv standup-web-server.yml`
   * The play will do the following:
     * Create a virtual machine
     * configure an additional interface
     * configure additional drives
     * wait for the eth1 interface to be available
     * run an ansible role that install apache httpd and copies over a default index
     * expose ssh and port 80 for web access

