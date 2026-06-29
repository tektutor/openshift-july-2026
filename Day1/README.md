
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
- containers will never be able to replace an Operating System or Virtualization
- in fact, in real-world scenarios, virtualization and containerization are used in combination
- it is a linux technology
- linux kernel features that enables containerization
  1. Namespace
     - helps isolation of containers from each other
  2. Control Groups (CGroups )
     - it helps us apply resource quota restrictions like
       - we can restrict how much RAM, disk and cpu can be utilized by a container
- container runtime
  - is a low-level software that manages container images and containers
  - it is not user-friendly, hence end-user like us never use container runtime directly
  - examples
    - runC
    - cRun
    - CRI-O
- container engine
  - is a high-level software that manages container images and containers
  - it is very user-friendly, but they depend on container runtimes internally to manage images and containers
  - examples
    - docker
    - podman
</pre>

## Info - Hypervisor High-Level Architecture

## Info - Docker High-Level Architecture


## Info - Docker image
<pre>
- is a blueprint of a docker container
- you can imagine docker image similar to Window12.iso (OS Image) or Ubuntu24.04.iso(OS Image)
- with the help of a docker image, we can create any number of docker containers
- docker images => typically has one application and its dependencies ( libraries, dependent tools, etc., )
- docker images are conservatively built, which means it only contains bare minimum tools required to run a specific appliction
- every docker images gets a unique name and unique id ( 256-bit HASH )
</pre>

## Info - Docker Container
<pre>
- is the running instance of a Docker Image ( Container Image )
- each container gets a unique name and ID (SHA Hash)
- each container gets its own dedicated software defined network stack ( 7 OSI Layers )
- each container get its own file system ( files & folders )
- each container uses about 7 namespaces
- each container gets one or more IP addresses ( generally Private IP )
</pre>

## Info - Docker Registry
<pre>
- is a collection of multiple docker images
- there are 3 types
  1. Local Docker Registry
     - is a folder created and maintained by Docker server on the same machine where it runs
     - for example, in linux distros, local docker registry is maintained under directory /var/lib/docker
  2. Remote docker registry
     - is a web site ( hub.docker.com ) maintained by Docker Inc and opensource community
  3. Private Docker registry
     - can be setup using JFrog Artifactory or Sonatype Nexus
</pre>

## Demo - Installing Docker community edition (Docker CE)
```
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker 
```

## Lab - Checking docker details
```
docker --version
docker info
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/612f7d88-7074-44aa-977e-a96a44a80a64" />
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/c6ace828-9e5a-49d5-a10a-8a84f70a068c" />

## Lab - Listing docker images from your local docker registry
```
docker images
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/80aca764-71d4-4789-bcfb-f7ba902d7e3f" />

## Lab - Downloading docker images from docker hub to local registry
```
docker pull hello-world:latest
docker pull ubuntu:latest

docker images
```

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/9f094fc2-908d-4fc4-be73-fdffd8b30fc0" />

## Lab - Deleting a docker image from your local registry
```
docker images | grep hello
docker rmi hello-world:latest
docker images | grep hello
```
<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/cacaa967-c82b-4967-8726-7c816c99a112" />

## Lab - Creating a container in the interactive(foreground) mode
From terminal 1
```
docker run -it --name ubuntu1-jegan --hostname ubuntu1-jegan ubuntu:latest /bin/bash
hostname
hostname -i
ls
exit
```

List all running containers from second terminal
```
docker ps | grep jegan
```

List all running containers you created
```
docker ps -a | grep jegan
```

<img width="1920" height="1200" alt="image" src="https://github.com/user-attachments/assets/068a94a2-0d61-4f58-929c-ad85c9864bb9" />


## Lab - Create a custom docker image

In your home directory, create a folder something like custom-docker-image
```
cd ~/
mkdir -p custom-docker-image
cd custom-docker-image
touch Dockerfile
```

Add the below content to your Dockerfile, you can run gedit to open windows notepad like editor
<pre>
FROM ubuntu:26.04

RUN apt update && apt install -y net-tools iputils-ping
RUN apt update && apt install -y default-jdk maven  
</pre>

Build your custom docker image
```
cd ~/custom-docker-image
docker build -t ubuntu-jegan:1.0 .
docker images | grep jegan
```

Create a container using your custom docker image
```
docker run -dit --name c1-jegan --hostname c1-jegan ubuntu-jegan:1.0 /bin/bash
docker exec -it c1-jegan /bin/bash
hostname
hostname -i
ping 8.8.8.8
ifconfig
ls
exit
```

List and see the container should still run because we created this container in background
```
docker ps
```

## Lab - Stopping a running container
```
docker ps | grep c1-jegan
docker stop c1-jegan
docker ps | grep c1-jegan
```



