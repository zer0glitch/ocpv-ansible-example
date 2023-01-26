# ocpv-ansible-example

## New phone, who dis?
This is a project to provide instruction and examples for the [zer0glitch.ocpv](https://github.com/zer0glitch/ocpv) ansible collection.
- What is OCP-V
- How to spin up a lab environment/prerequisites
- How to configure your lab environment
- Install OCP-V + Hyper-Converged
- VM Networking in OCP
  - Configure NNCP
  - Routes/Services
- Install Virtual Machines (VM's)
- Learn how to change VM configuration
- Learn how to use VM templates
  - cloud-init


### Alright, so what do I need?
In order to begin this course we have to assume you have met the below requirements:
- You have access to a workstation with an internet connection (I sure hope you do if you're reading this!)
- You have access to RHPDS.
or
- You have your own enviornment with capable of running Openshift Virtualization

## Let's get started!

### Wait. How do I start again?
#### Dis is a replacement for "Lab Configuration" TODO: explain pre-reqs
#### Order your virtual environment rhpds
* Go to https://demo.redhat.com
* Search for "Virtualization"
* Select Hands on with Openshift Virtualization
* Order
* ssh to the server with the credentials provided
* Configure the demo environment 
```
# install vim and git
sudo dnf install vim git -y

# clone the examples project
git clone https://github.com/zer0glitch/ocpv-ansible-example.git

# cd into the directory
cd ocpv-ansible-example/

# run the configure script to to install software, and a RHPDS enviornment.  This may change if you are using your own environment.
./config.sh
```
* Gather kubeadmin password (As of writing this, RHPDS does not provide it for some reason) 
```
sudo cat /home/lab-user/install/auth/kubeadmin-password
```
* Use kubeadmin and the discovered password to log into the openshift console

### CNV Installation via Ansible (Automated Install)

  * Install Operator and Hyper-converged utilizing the [OCP Virtualization install role](https://github.com/zer0glitch/ocpv/blob/main/roles/install/tasks/main.yml)

```
---
- name: Install openshift virtualization
  hosts: localhost
  tasks:

  - name: import deploy_cnv
    import_role:
            name: zer0glitch.ocpv.install
```

  * Run the following command
```
ansible-playbook -vv examples/deploy-cnv.yml
```
  * Navigate to Operators-->Installed Operators
  * Select Project: "openshift-cnv"
  * Select "Show all Projects"
  * Select "Openshift Virtualization"
  * Select "All Instances" 
  * You will see the install completed successfully

### Creating a Virtual Machine with ansible (Automated Install)
  * Create a virtual machine
  * The role will use a virtual machine jinja2 [template](https://github.com/zer0glitch/ocpv/blob/main/roles/create_vm/templates/vm-template.yaml.j2)
  * The template offers benefits over just a standard openshift VM template, by using Ansible variables, the template can be customized quickly.

  * Create a basic virtual machine using the [create_vm](https://github.com/zer0glitch/ocpv/tree/main/roles/create_vm) role.  Using the [basic vm playbook](examples/basic-vm.yml)

```
ansible-playbook -vv examples/basic-vm.yml
```

  * Go to the UI and select *Virtual Machines* in the menu
  * Or from the command line

```
watch oc get vms --all-namespaces
```

### Configure a bridged network [Network configuration](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.11/html/openshift_virtualization/node-networking)
  * get the NodeNetworkState
```
oc get nns
```
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
 ```
oc get nns -oyaml worker-0
```
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
  * Or use a shortcut
  ```
oc get nns -o jsonpath='{range .status.currentState.interfaces[*]}{"NAME: "}{.name}{"\t\tIPINFO: "}{.ipv4.address[*].ip}{"\t\t\tENABLED: "}{.ipv4.enabled}{"\n"}' worker-0
  ```
  * Create a bridge for ens5 with dhcp 
   ```
   cat <<EOT >> nodenetworkconfigurationpolicy.yml
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
   EOT
   ```
```
oc apply -f nodenetworkconfigurationpolicy.yml
```

### Creating a Virtual Machine with ansible and configure a web server (Autmmated Install)
   * Look at the [setup-web-server.yml playbook](https://github.com/zer0glitch/ocpv-ansible-example/blob/main/standup-web-server.yml)
   * Run the following playbook `ansible-playbook -vv examples/standup-web-server.yml`
   * The play will do the following:
     * Create a virtual machine
     * configure an additional interface
     * configure additional drives
     * wait for the eth1 interface to be available
     * run an ansible role that install apache httpd and copies over a default index
     * expose ssh and port 80 for web access

