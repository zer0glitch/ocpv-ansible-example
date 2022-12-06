# ocpv-ansible-example

## Assumptions and Pre-Requisites:
- Using RHPDS
- Using Openshift Data Foundation on top of Local Storage Operator

## What is OpenShift Virtualization?
 - Explain things like what CNV (Container Native Virtualization) is.
 - how does it compare to more traditional virt platforms, including common pain points. (Probably best to pull this from sales docs. can provide more info if necessary)
 - Some benefits to OCP-V? (This can be removed if we want)
 
## Install:

### CNV Installation via OpenShift Console (Graphical Install)

  * Install Operator
  * Create Hyper-converged

### CNV Installation via Ansible (Hacker Install)

  * Install Operator and Hyper-converged

### VM Installation and Configuration via OpenShift Console (Graphical Install)

#### Templating
.  Run playbook with default templates
   - Look at basetemplate
     - Edit the the project to match your user.  For the lab environment it is user{number}
       *This will create the VMs in this namespace*
     - You will see that This calls the vm role takes 3 parameters
       - The _server_name_: this is the name of the virtual machine
       - _template_name_: This is the name of the base template we are going to use. (We will examine the templates before running the playbook)
       - _default_password_:  This is the password for the cloud-init user.  Later we will show how to add ssh keys using a custom cloud-init)

```
---
- hosts: localhost
  tasks:
  - import_role:
            name: basetemplate
    vars:
      *project: jwhetsel*
      vms:
              - name: server-small
                template_name: fedora-server-small
                cloud_password: r3dh4t1!
              - name: server-medium
                template_name: fedora-server-medium
                cloud_password: r3dh4t1!
              - name: server-large
                template_name: fedora-server-large
                cloud_password: r3dh4t1!
```
   - In the user interface navigate to Virtualization-->Templates and select fedora-server-small
     - Scroll to "Scheduling and resources requirements"
     - Look under flavor to see the CPU and Memory required
     - Click the "Network Interfaces" Tab and see that this VM is using the Pod network, this means that the VM will not be accessible outside of the Openshift Network.  We will show later how we can use bridged networks
     - Click on the "Disks" Tag.  by default we will have a single 30 GiB drive, and our cloud-init drive.  *The cloud init drive is stored a secret in the namespace*

   - Now run the following playbook
     - the playbook will use the oc command installed on the system to process the templates and create the virtual machiens.  You can look at the task in the role to see the commands being run.
     - `ansible-playbook -vv setup-lab-server.yml`
     - In the openshift console navigate to Virtualization-->Virtual Machines
       - Select the project for your user
       - The vitual machines will take a minute to come up, you can look at the teminal to see the init.
  
.  Working with openshift virtual machine templates
   - use `oc get templates -n openshift` to see a lis tof templates
   - pic any template that you like.  and look at the components.  For this example we will be using fedora-server-small `oc edit template -n openshift fedora-server-small` 
   


name: "{{ vm_name }}" 
name: "{{ boot_source }}"
storage: "{{ root_volume_size|default('30') }}Gi"
cores: "{{ cores|default('1') }}"
sockets: "{{ sockets|default('1') }}"
threads: "{{ threads|default('1') }}"
memory: "{{ memory|default('2') }}Gi"
user: "{{ user|default('redhatuser') }}"
password: "{{ password|default('r3dh4t1!') }}"



.  How to customize
   Memory
   Drive
   CPU
   Network

. Uploading custom image

. start/stop

. using ansible to configure your vm
