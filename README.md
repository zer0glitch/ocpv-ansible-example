# ocpv-ansible-example

## Introduction:
Welcome to the OpenShift Virtualization Lab!
During this course you will learn how to:
- Install OpenShift Virtualization + Hyper-Converged
- Install Virtual Machines (VM's)
- Learn how to change VM configuration
- Learn how to use VM templates
- Optionally: Learn how to automate it all!

### Assumptions:
In order to begin this course we have to assume you have met the below requirements:
- You have access to a workstation with an internet connection (I sure hope you do if you're reading this!)
- You have access to RHPDS.

If you at least have the above, then let's get going!
### What is OpenShift Virtualization?
 - Explain things like what CNV (Container Native Virtualization) is.
 - how does it compare to more traditional virt platforms, including common pain points. (Probably best to pull this from sales docs. can provide more info if necessary)
 - Some benefits to OCP-V? (This can be removed if we want)

### 2. Lab configuration
# Order your virtual environment rhpds
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

#### CNV Installation via OpenShift Console (Graphical Install)

  * Install Operator
  * Create Hyper-converged

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

#### CNV Installation via Ansible (Autmmated Install)
  * Create a virtual machine
  * The role will use a virtual machine jinja2 [template](https://github.com/zer0glitch/ocpv/blob/main/roles/create_vm/templates/vm-template.yaml.j2)
  * The template offers benefits over just a standard openshift VM template, by using Ansible variables, the template can be customized quickly.
    * vm_name: fedora-custom # Name of the virtual machine
    * boot_source: fedora # boot source
    * boot_source_type: pvc # booting from a PVC
    * root_volume_size: 30 # root volume size
    * cores: 1 # number of cores
    * sockets: 1 # number of sockets
    * threads: 1 # Number of threads
    * memory: 2 # memory in Gigabytes
    * network_interfaces:
      - name: eth1 # Additional interface name
        bridge_name: br0 # Bridge to attach interface to
        vlan_id: 222 # (Optional) vlan id
    * data_volumes: # additional drives to add to the system
      - name: drive1 
        size: 30Gi
      - name: drive2
        size: 30Gi
    * cloud_init: | # user defined cloud init
              #cloud-config
              user: "jamie"
              password: "r3dh4t1!"
              chpasswd: { expire: False }
    * cloud_init_secret: | # will override cloud_init, string will be stored in a secret, which allows for larger cloud init definitions.  This could also be a file or jinja2 template
        #cloud-config
        user: "jamie"
        password: "r3dh4t1!"
        chpasswd: { expire: False }
        ssh_authorized_keys: {{ lookup('file', '~/.ssh/id_rsa.pub') }}

    * Run `ansible-playbook -vv create-vms.yaml` to create a virtual machine
    * Run `oc get vms --all-namespaces` or go to the UI and select *Virtual Machines* in the menu

# Configure a bridged network [Network configuratoin](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.11/html/openshift_virtualization/node-networking)
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
    apiVersion: nmstate.io/v1
    kind: NodeNetworkConfigurationPolicy
    metadata:
      name: ens5-br1-bridge
    spec:
      nodeSelector: 
        node-role.kubernetes.io/worker: "" 
      desiredState:
        interfaces:
          - name: br1
            description: Linux bridge with eth1 as a port 
            type: linux-bridge
            state: up
            ipv4:
              dhcp: true
              enabled: true
            bridge:
              options:
                stp:
                  enabled: false
              port:
                - name: eth1
    ```

wait `oc get vmi -o \
  jsonpath="{.status.interfaces[?(@.interfaceName=='eth1')].ipAddress}"  \
  -n user1 fedora-custom-network
`
