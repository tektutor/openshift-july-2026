# Day 2

## Info - Container Orchestration Platform
<pre>
- in order to deploy your application into Container Orchestration Platform, we must first containerize them
- In real world applications, no one manages containerized application workloads manually
- In real world, Container Orchestration Platforms manage our containerized application workloads
- They provide
  - in-built monitoring, health-check, readiness check, liveliness check for your application
  - self-healing to your applications
  - a way to scale up/down your application instances based on user traffic
  - rolling update
    - upgrading your application from one version to other without any downtime
    - rolling back to earlier stable versions are also possible
  - ways to collect performance metrics
- any container orchestration platform works as a cluster of many nodes
- nodes are nothing but Physical Servers or Virtual Machines in private/public cloud
- examples
  - Docker SWARM
  - Kubernetes
  - Rancher
  - Red Hat Openshift
  - AWS eks
  - AWS ROSA
  - Azure aks
  - Azure ARO
</pre>

## Info - Docker SWARM
<pre>
- is developed by Docker Inc as an open-source project
- it supported only Docker Containerized applications
- it is a very light-weight setup that works in laptop/dekstop with normal configurations
- it is ideal setup for learning purpose
- it is ideal for Dev/QA environment
</pre>

## Info - Kubernetes
<pre>
- is a Container Orchestration platform developed in Golang by Google
- intially it was called borg, Google has been using this container orchestration platforms internally within google
  for several years
- it is production-grade because google used it on complex projects many years
- it supports many different container runtimes/engines
- Kubernetes supports something called CRI(Container Runtime Interface)
- any container runtime/engine that must be supported by Kubernetes they have to implement the CRI
- Kubernetes can/will interact with any type of Container Runtime/Engine via CRI
- Kubernetes supports 2 types of nodes
  - Master Node
    - this is where Control Plane components will be running
    - Control Plane Components
      1. API Server
      2. etcd key/value database
      3. scheduler
      4. Controller Managers( collection of many controllers )
  - Worker Node
    - this is where user applications will be running
- Kubernetes is primarily a CLI application
- Kubernetes doesn't support 
  - a production-grade webconsole
  - User Management
  - Internal Container Registry ( out of box )
  - Prometheus/Grafana performance metrics collection ( out of box )
- Kubernetes supports basic building blocks to extend the Kubernetes features by adding
  - your own custom resources
  - your own custom controllers
- Kubernetes allows one to deploy their application only from a Container Image
- In Kubernetes Master/Worker nodes, we can choose to install any Linux OS distribution (ubuntu, rocky, fedora, RHEL, etc., )
</pre>


## Info - Red Hat Openshift
<pre>
- is a Red Hat's distribution of Kubernetes
- Openshift is developed on top of opensource Kubernetes
- Hence, Openshift is a superset of Kubernetes
- Openshift is Kubernetes with batteries included
- Openshift comes with these additional features on top of what is already supported by Kubernetes
  1. User Management
  2. Production Web-console (GUI)
  3. Many additional features
     - Route
     - S2I ( Source to Image )
       - one can deploy their application from plain source code coming from GitHub or any other version control
       - supports many different strategies
         - docker
         - source
         - pipeline
  4. Internal Container Registry
- Red Hat acqurired a company named CoreOS
  - CoreOS organization had several interesting products
    - rkt(pronounced as Rocket) - container runtime
    - CoreOS - Linux based minimal & secure operating system good enough for Container Orchestration Platform
    - Network addons - Flannel
- Red Hat Openshift starting from v4.x,
  - supports only Red Hat Enterprise CoreOS operating (RHCOS) in Master Nodes
  - supports either Red Hat Enterprise Linux(RHEL) or RHCOS in Worker Node
  - Red Hat Openshift generally recommends to install RHCOS in all nodes
  - supports only CRI-O Container Runtime
  - RHCOS Operating System
    - is an Container Orchestration Platform optimized minimal and secured Operating System
      based on RHEL
    - this OS comes with CRI-O & Podman pre-installed
    - it is an immutable OS many restrictions
    - some of the folders like /var, /bin, /usr/bin are all treated as read-only folder
    - only through Machine Config Operators we can update certain reserved folders, meaning
      application won't be able to modify those restricted folders
    - Ports 0-1024 are reserved for Openshift's internal use
</pre>

## Info - Pod
<pre>
- Pod is a logical grouping of related containers
- Pod is record stored in etcd database
  - is a configuration object stored in etcd database
  - what really runs on nodes is containers
- Unlike Docker container where each container get a dedicated IP address, in case of Pod, all containers
  that are part of a Pod they all share the same Private IP address
- applications runs with a Pod container
- Every Pod get its own port range i.e 0 to 65535
- if there are two container c1 and c2 within Pod P1, if c1 is using port 8080 then c2 won't be able to use port 8080
- the containers within the same Pod, they can communicate with each with regular IPC mechanisms
</pre>

## Info - Types of applications that can be deployed into Openshift
<pre>
- Stateless applications
  - k8s/Openshift supports a resource called Deployment
- Stateful applications
  - k8s/Openshift supports a resource called StatefulSet
- Application that performs a one-time activity and stops in some time
  - Job
- Application that must be invoked periodically on a particular day and time
  - CronJob (this internally used Job)
- Applications that run one instance per Node
  - DaemonSet
</pre>


## Lab - Login to openshift from command-line
```
cat ~/openshift.txt
oc login --username=kubeadmin --password=VVnz6-ezZ9W-RVbw4-NPK3R https://api.ocp4.palmeto.org:6443 --insecure-skip-tls-verify
```


## Lab - Listing Nodes in Red Hat Openshift
```
oc version
kubectl version

oc get nodes
kubectl get nodes

oc get nodes -o wide
kubectl get nodes -o wide
```

## Lab - Finding additional meta-data about a node
```
oc describe node/master01.ocp4.palmeto.org
oc describe node/worker01.ocp4.palmeto.org
```

