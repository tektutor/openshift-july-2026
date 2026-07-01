# Day 3

## Info - You can find Red Hat Base images here
<pre>
https://catalog.redhat.com/en/software/containers/explore
</pre>

## Info - You can find other Red Hat Openshift compatible images here
<pre>
https://catalog.redhat.com/en/search?searchType=Containers
</pre>  

## Info - What happens internally in Openshift when we deploy an application
```
oc project jegan-project
oc create deploy nginx --image=docker.io/bitnami/nginx:1.26 --replicas=3
```

Note
<pre>
- oc client tool makes a REST call to API Server requesting the API Server to create a deployment
- Once API Server receives the request from oc client, it creates a Deployment database entry in etcd database
- API Server then sends broadcasting event saying new Deployment created along with deployment details
- Deployment Controller receives this event, it then makes a REST call to API Server requesting it to create a ReplicaSet for the nginx deployment
- API Server creates a ReplicaSet db entry(new record) in the etcd database
- API Server sends a broadcast event saying new ReplicaSet created
- ReplicaSet Controller receives the event, it then makes a REST call to API Server requesting it to create 3 Pods
- API Server create 3 Pod records in the etcd database
- API Server sends broadcast event for each new Pod created in the etcd database
- Scheduler receives the event, it then identifies a healthy node where the new Pod can be deployed
- Scheduler makes a REST call to API Server to send it scheduling recommendataion. This will be done for each Pod.
- API Server receives the scheduling recommendations from Scheduler, it then retrieves the Pod record from etcd and updates it status as Scheduled to so and so node
- API Server sends a broadcasting event saying Pod1 scheduled to Worker01 node, this happens for each Pod.
- Kubelet Container Agent that runs on Worker01 node receives the event, it then pull the container image, creates and starts the container on Worker01
- Kubelet monitors the status of the Container created for Pod1, and it periodically updates the status back to API Server in a heart-beat fashion
- API Server receives these updates, retrieves the Pod database entry from etcd and updates the Pod status
</pre>
![Openshift](openshift-internals.png)

## Lab - Deploying a stateless application in declarative style
```
# Delete your existing project
oc delete project jegan

# Create a new project
oc new-project jegan

# Generate the declarative manifest file to deploy nginx
oc create deploy nginx --image=image-registry.openshift-image-registry.svc:5000/openshift/bitnami-nginx:1.26 --replicas=3 --dry-run=client -o yaml

# Redirect the output shown to a yaml file
oc create deploy nginx --image=image-registry.openshift-image-registry.svc:5000/openshift/bitnami-nginx:1.26 --replicas=3 --dry-run=client -o yaml > nginx-deploy.yml

# Deploy the nginx in declarative fashion
oc create -f nginx-deploy.yml --save-config

# In the template section of the nginx-deploy.yml add additional labels and apply
oc apply -f nginx-deploy.yml

# List the deploy,replicaset and pods
oc get deploy,rs,po

## Delete the deployment declaratively
oc delete -f nginx-deploy.yml
oc get deploy,rs,po
```

## Lab - Creating a ClusterIP Internal Service in declarative style
Create a pod.yml with code below
<pre>
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: test
  name: test-pod
spec:
  containers:
  - image: image-registry.openshift-image-registry.svc:5000/openshift/hello:latest
    imagePullPolicy: IfNotPresent
    name: test  
</pre>

Create the test pod
```
oc project jegan-project
oc apply -f pod.yml
oc get pods
```

Let's create the nginx deployment in declarative style
```
oc create deploy nginx --image=image-registry.openshift-image-registry.svc:5000/openshift/bitnami-nginx:1.26 --replicas=3 --dry-run=client -o yaml
oc create deploy nginx --image=image-registry.openshift-image-registry.svc:5000/openshift/bitnami-nginx:1.26 --replicas=3 --dry-run=client -o yaml > nginx-deploy.yml
oc apply -f nginx-deploy.yml
```

Let's create the ClusterIP Internal service declaratively
```
oc expose deploy/nginx --type=ClusterIP --port=8080 --dry-run=client -o yaml
oc expose deploy/nginx --type=ClusterIP --port=8080 --dry-run=client -o yaml > nginx-clusterip-svc.yml
oc apply -f nginx-clusterip-svc.yml
oc get svc
oc describe svc/nginx
```

Let's test the clusterip internal service using the test pod we created
```
oc rsh pod/test-pod
curl http://nginx:8080 # Service discovery - accessing service by its name
curl http://nginx.jegan-project.svc.cluster.local:8080 # Recommended compared to previous command
curl http://172.30.240.164:8080
```

## Lab - Creating an external NodePort service in declarative style
```
oc project jegan-project

# Delete existing clusterip service before creating nodeport service
oc delete -f nginx-clusterip-svc.yml

oc expose deploy/nginx --type=NodePort --port=8080 --dry-run=client -o yaml
oc expose deploy/nginx --type=NodePort --port=8080 --dry-run=client -o yaml > nginx-nodeport-svc.yml
oc apply -f nginx-nodeport-svc.yml
oc get svc
oc describe svc/nginx # Get the NodePort from this command and substitute below

oc get nodes -o wide
```

Let's test the nodeport external service
```
curl http://192.168.100.11:31728 # Master1 IP
curl http://192.168.100.12:31728 # Master2 IP
curl http://192.168.100.13:31728 # Master3 IP
curl http://192.168.100.21:31728 # Worker1 IP
curl http://192.168.100.22:31728 # Worker2 IP
curl http://192.168.100.23:31728 # Worker3 IP

curl http://master01.ocp4.palmeto.org:31728
curl http://master02.ocp4.palmeto.org:31728
curl http://master03.ocp4.palmeto.org:31728
curl http://worker01.ocp4.palmeto.org:31728
curl http://worker02.ocp4.palmeto.org:31728
curl http://worker03.ocp4.palmeto.org:31728

```
