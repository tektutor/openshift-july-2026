# Day 1

## Info - Hypervisor Overview
<pre>
- nothing but virtualization 
- with virtualization/hypervisor software, we can run multiple OS side by side on the same laptop/desktop/workstation/server
- there are 2 types of Hypervisors
  1. Type 1 
     - a.k.a Baremetal Hypervisor
     - is used in Workstation & Server
     - performance wise it offers almost near native performance ( 3% less performance as opposed to running a OS on direct H/W )
     - this can be installed directly on top of a H/W with no Operating System
     - examples
       1. VMWare vSphere(vCenter) - Paid
       2. Linux KVM ( opensource & Free )
       3. Microsoft Hyper-V
  2. Type 2
     - a.k.a Hosted Hypervisor
     - this can be installed only top of a Host Operating System ( Windows, Mac OSX, Linux, etc )
     - is used in Workstation, Desktops & Laptops
     - examples
       - Oracle VirtualBox ( Free - Windows/Linux/Mac )
       - VMWare Wokstation ( Free - after Broadcom acquired VMWare - Windows, Linux, Mac )
       - VMWare Fusion ( Mac OS-X - Need a commercial license )
       - Parallels ( Mac OS-X - Need a commercial license )
- virtualization helps organization save cost in many fold
  - with less physical servers, many virtual machines(Guest OS) can be supported
  - saves cost in terms of procuring less physical servers
  - saves cost in terms of power consumption
  - saves cost in terms of Air Condition 
  - saves cost in terms of Sound proofing
  - saves cost in terms of Real estate rental/leasing
- this type of virtualization is called heavy-weight 
  - because each VM requires dedicated Hardware resources
  - each VM runs a fully functional OS with its own dedicated OS Kernel
- each VM, represents one fully function Operating System
</pre>

## Info - Containerization
<pre>
- application virtualization technology
- it is light weight, because each container represents a single application not an Operating System
- all the containers that runs on top a OS shares the Hardware resources available on the underlying OS
</pre>
