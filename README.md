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


## Meat and potatoes of Virtual Machines!

### 1. VM Installation
In this section you will learn how to install VM's via the OCP Console, the `oc` command, and Ansible.
Key things to understand when creating VM's in OpenShift:
- Using templates allow you to pre-define many variables ahead of time, and tailor to each deployment as necessary
   - Pros:
   - Cons:
- Using full VM configs will allow you to customize every VM exactly how you need it
   - Pros:
   - Cons:

Let's begin! (pick your poison)

<details>
<summary> <h4> via OpenShift Console </h4> </summary>

##### Templates
.  By default we need to have a boot image avaiable 
   - Option 1: Create a VM and import from the registry which will create a DataVolume
   - Option 2: use a boot source in our template, which will need to be removed
   - Option 3: Upload our own data volume
   - Option 4: https://github.com/kubevirt/containerized-data-importer/blob/v1.53.0/doc/image-from-registry.md#import-registry-image-into-a-data-volume-using-node-docker-cache


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
</details>

<details>
<summary> <h4> via Ansible: (Autmmated Method) </h4> </summary>

#####  Uploading a cloud image
   - Download the desired cloud image, for the example we will use fedora
     . `curl -OL https://download.fedoraproject.org/pub/fedora/linux/releases/37/Cloud/x86_64/images/Fedora-Cloud-Base-37-1.7.x86_64.qcow2`
   - upload the image to `openshift-virtualization-os-images` **Note: All boot images must be stored in this project**
     . `virtctl --namespace openshift-virtualization-os-images image-upload dv fedora37 --image-path=Fedora-Cloud-Base-37-1.7.x86_64.qcow2 --size 20Gi`

##### Run playbook with default templates
   - Look at basetemplate
     - Edit the the project to match your user.  For the lab environment it is user{number}
       *This will create the VMs in this namespace*
     - You will see that This calls the vm role takes 3 parameters
       - The _server_name_: this is the name of the virtual machine
       - _template_name_: This is the name of the base template we are going to use. (We will examine the templates before running the playbook)
       - _default_password_:  This is the password for the cloud-init user.  Later we will show how to add ssh keys using a custom cloud-init)
<details>
 <summary> Example playbook </summary>
 
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
</details>

   - Now run the following playbook
     - the playbook will use the oc command installed on the system to process the templates and create the virtual machiens.  You can look at the task in the role to see the commands being run.
     - `ansible-playbook -vv setup-lab-server.yml`
     - In the openshift console navigate to Virtualization-->Virtual Machines
       - Select the project for your user
       - The vitual machines will take a minute to come up, you can look at the teminal to see the init.
</details>

### 2. VM Configuration

#### VM Configuration via Ansible (Autmmated method)

##### Templates:
   - use `oc get templates -n openshift` to see a lis tof templates
   - pic any template that you like.  and look at the components.  For this example we will be using fedora-server-small `oc edit template -n openshift fedora-server-small` 

   - There are a limited amount of options available.  

```
- description: VM name
  from: fedora-[a-z0-9]{16}
  generate: expression
  name: NAME
- description: Name of the PVC to clone
  name: SRC_PVC_NAME
  value: fedora
- description: Namespace of the source PVC
  name: SRC_PVC_NAMESPACE
  value: openshift-virtualization-os-images
- description: Randomized password for the cloud-init user fedora
  from: '[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}'
  generate: expression
  name: CLOUD_USER_PASSWORD
```

   - The base templates allow for very limited configuration of the system.  One method of create a virtual machine simply is to use `oc process fedora-server-small -p NAME=myserver | oc apply -f -`
   - You will see a new small fedora virtual machine with the name `myserver`
   - You can start your own jinja2 template by running `oc process fedora-server-small -p NAME=vm_name`
   - If you wish to have a more cutomizable environment, is to save off a processed template and modify it to suit our needs.  You can see an example output of this here (https://github.com/zer0glitch/ocpv-ansible-example/blob/main/roles/create_vm/templates/vm-template.yaml.j2)
   - The preconfigured template above has the following variables
     - _vm_name_: The name of the virtual machine, this is used throughout the template to tag additional resources
     - _boot_source_: The boot source will be the base server
     - _root_volume_size|default('30')_:
     - _cores|default('1')_:
     - _sockets|default('1')_:
     - _threads|default('1')_:
     - _memory|default('2')_:
     - _user|default('redhatuser')_:
     - _password|default('r3dh4t1!')_:


##  How to customize
   Memory
   Drive
   CPU
   Network

## Uploading custom image

## start/stop
