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

# Configure a bridged network
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

