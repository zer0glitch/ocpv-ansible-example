## New phone, who dis?
This is a project to provide instruction and examples to teach you OpenShift Virtualization (OCP-V) via the [zer0glitch.ocpv](https://github.com/zer0glitch/ocpv) ansible collection.
During the course of your time with us, you will have learned the following:
- What is OCP-V
- How to spin up a lab environment/prerequisites
- How to configure your lab environment
- How to install OCP-V + Hyper-Converged
- How VM Networking in OCP works including a brief intro to:
  - How to Configure an NNCP
  - How Routes/Services should work
- How to create Virtual Machines (VM's)
- How to change VM configuration
- How to use VM templates
  - cloud-init


### Alright, so what do I need?
In order to begin this course we have to assume you have met the below requirements:
- You have access to a workstation with an internet connection (I sure hope you do if you're reading this!)
- You have access to RHPDS.
or
- You have your own enviornment with capable of running Openshift Virtualization

NOTE: Since this course is designed to run out of RHPDS, the assumption is your bastion host will be a linux host.

## Let's get started!

### So what is this "OCP-V" you speak of?
OpenShift Virtualization is an add-on to OpenShift Container Platform that allows you to run and manage virtual machine workloads within a container native ecosystem.
OCP-V adds new objects into your OpenShift Container Platform cluster via Kubernetes custom resources to enable virtualization tasks. These tasks include:
- Creating and managing Linux and Windows virtual machines
- Connecting to virtual machines through a variety of consoles and CLI tools
- Importing and cloning existing virtual machines
- Managing network interface controllers and storage disks attached to virtual machines
- Live migrating VM's between nodes


### Wait. How do I start again?
Well, it depends. Do you even RHPDS?
<details open>
<summary> <h4> Order your virtual environment via RHPDS </h4> </summary>

* Go to the OCP-V [RHPDS Page:](https://demo.redhat.com/catalog?search=Virtualization&item=babylon-catalog-prod%2Fopenstack.hands-on-ocp-virtualization.prod)
* Let's order the thing!
  * Select "Training"
  * In the "Purpose" drop down, select "As part of course"
  * Leave "Salesforce ID" empty
  * Read the "IMPORTANT PLEASE READ"
  * Check the checkbox
  * *Now* click "Order"
* Wait for your environment to spin up
* ssh to the server with the credentials provided
* Continue to the next steps. We'll configure your environment shortly

</details>

<details open>
<summary> <h4> But what if I don't have RHPDS? </h4> </summary>
  
WIP: Ensure you have the following available to you:
- An OCP 4.10 and up cluster
- A bastion host with the following:
      - Ansible
      - Python

</details>

### No really. What do I do?
I'm glad you asked! (took you long enough...)
All we have to do to start, is to make sure you have access to your bastion host, and start typing away!

NOTE: you'll need SSH or console access to a bastion machine. For our RHPDS peeps, this would be provided as an SSH connection.

Once you're ready, see the below code block to run some commands to configure your environment.
 
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
NOTE: We recommend you save this password for later
```
sudo cat /home/lab-user/install/auth/kubeadmin-password
```
* Use kubeadmin and the discovered password to log into the openshift console (the web GUI thing)

## Sweet! Can we start doing the Virtualization?
Of course! Let me explain some things first.
1) The assumption here is that you've already started and configured your lab environment correctly, and have a CLI up at the root of the newly cloned git directory. (as lab-user, not root)
2) Each step is laid out in the order it should be accomplished. If you're already familiar with how to accomplish a step, or you've already done it in your environment, skip to the next.
3) Each step should also have a section for how to do things via the OpenShift Console, but the focus of this course is on automating these tasks.

<details open>
<summary> <h4> (Ansible) OCP-V Installation </h4> </summary>

  * Install the Operator and Hyper-converged resource utilizing the [OCP Virtualization install role](https://github.com/zer0glitch/ocpv/blob/main/roles/install/tasks/main.yml)
  * To utilize the role, run the following playbook
```
ansible-playbook -vv examples/deploy-cnv.yml
```
  * Navigate to Operators-->Installed Operators
  * Select Project: "openshift-cnv"
  * Select "Show all Projects"
  * Select "Openshift Virtualization"
  * Select "All Instances" 
  * You will see the install completed successfully

</details>

<details open>
<summary> <h4> Networking: Creating a bridged network </h4> </summary>

Doc links:
- [Network configuration](https://docs.openshift.com/container-platform/4.10/virt/node_network/virt-updating-node-network-config.html)
- [Connecting a VM to a Bridged Network](https://docs.openshift.com/container-platform/4.10/virt/virtual_machines/vm_networking/virt-attaching-vm-multiple-networks.html)

Steps:
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

  * look at the first worker node (worker-0 in this case) to see what interfaces are available, and which one we would like to bridge
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
</details>

<details open>
<summary> <h4> (Ansible) Creating a VM </h4> </summary>

### Standard VM, and intro to creating VMs:
We're going to be using one of the roles from the zer0glitch OCP-V Galaxy repo.
  * The role will use a virtual machine jinja2 [template](https://github.com/zer0glitch/ocpv/blob/main/roles/create_vm/templates/vm-template.yaml.j2)
  * The template offers benefits over just a standard openshift VM template, by using Ansible variables, the template can be customized quickly.

  * Create a basic virtual machine using the [create_vm](https://github.com/zer0glitch/ocpv/tree/main/roles/create_vm) role.  Using the [basic vm playbook](examples/basic-vm.yml)

```
ansible-playbook -vv examples/basic-vm.yml
```

  * To watch things the pretty way, go to the OCP Console and select *Virtual Machines* in the menu
  * Or to watch it from command line, run the below command (from your bastion host)

```
watch oc get vms --all-namespaces
```

### Now let's make it more complicated with a web server!
  
   * Look at the [setup-web-server.yml playbook](https://github.com/zer0glitch/ocpv-ansible-example/blob/main/examples/standup-web-server.yml)
   * Run the following playbook 
```
ansible-playbook -vv examples/standup-web-server.yml
```
   * The play will do the following:
     * Create a virtual machine
     * configure an additional interface
     * configure additional drives
     * wait for the eth1 interface to be available
     * run an ansible role that install apache httpd and copies over a default index
     * expose ssh and port 80 for web access
  
</details>
  
  
### This is cool, but I am disconnected
There are a few considerations for a disconnected environment.
   * How do I load a custom boot image?
     * Use the opnshift-virtualization-os-images to store 
     * make sure you have `virtctl` installed
     * Put your QCOW on the local system
     * `virtctl --namespace openshift-virtualization-os-images image-upload pvc fedora-pvc --size=10Gi --image-path=/images/fedora30.qcow2`  
     * virtctl --namespace openshift-virtualization-os-images upload-image pvc `boot source parameter in the create_vm role` --size=10Gi --image-path=/images/fedora30.qcow2

   * Example create a FreeBSD based VM off a custom image
```
# Download the cloud image
curl -O https://object-storage.public.mtl1.vexxhost.net/swift/v1/1dbafeefbd4f4c80864414a441e72dd2/bsd-cloud-image.org/images/freebsd/13.0/freebsd-13.0-zfs.qcow2

# upload the boot image
virtctl --insecure-skip-tls-verify=false --namespace openshift-virtualization-os-images image-upload pvc  freebsd13 --size=10Gi --image-path=freebsd-13.0-zfs.qcow2 --insecure

# Create the playbook to create the VM
cat <<EOT >> freebsd-vm.yml
---
- hosts: localhost
  gather_facts: false
  tasks:
  - name: create namespace for VMS
    become: False
    kubernetes.core.k8s:
      kubeconfig: ~/.kube/config
      definition:
        kind: Project
        apiVersion: project.openshift.io/v1
        metadata:
          name: "user1"
          labels:
            kubernetes.io/metadata.name: "user1"

  - include_role:
      name: zer0glitch.ocpv.create_vm
    vars: 
      project: user1
      vm_name: freebsd
      boot_source: freebsd13
      boot_source_type: pvc
      root_volume_size: 30
      cloud_init: |
              #cloud-config
              user: "jamie"
              password: "r3dh4t1!"
              chpasswd: { expire: False }
EOT
     
ansible-playbook -vv freebsd-vm.yml

```
     

