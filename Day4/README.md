# Day 4

## Demo - Statefulset - mysql cluster
```
cd ~/openshift-july-2026
git pull
cd Day4/statefult
oc apply -f sfs.yml
oc get pods -w
```

## Lab - Node Affinity
Note
<pre>
- There are two types of Node Affinity
  1. Preferred
     - In this case, the scheduler will try to locate nodes that meets the criteria mentioned under preferred
       node affinity section, if scheduler finds such nodes, your application gets deployed there
     - In case the scheduler is not able to find nodes that meets your criteria, the pods gets deployed in any node
  2. Required
     - In this case, the scheduler will only deploy your pods on nodes that meets the criteria
     - Until scheduler finds such nodes that meets your criteria, your pods will be in the Pending state
</pre>

Let's try the preferred node affinity
```
cd ~/openshift-july-2026
git pull
cd Day4/node-affinity
cat preferred-node-affinity.yml
oc project jegan-project

# List all nodes that has label disk=ssd
oc get nodes -l disk=ssd

# Assuming node nodes meets that criteria, let's see what scheduler does in this scenario
oc apply -f preferred-node-affinity.yml
oc get pods -o wide # As the scheduler couldn't find nodes that has label disk=ssd, it would have deployed your pods as usual

# Let's label a node with lab disk=ssd
oc label node/worker03.ocp4.palmeto.org disk=ssd
oc get nodes -l disk=ssd

# List and see to note the pods deployed already will not be redeployed to worker03 as node affinity is not applied on already
# deployed pods
oc get pods -o wide

# Let's delete the deployment and redeploy
oc delete -f preferred-node-affinity.yml
oc apply -f preferred-node-affinity.yml
oc get pods -o wide # Now all your nginx pods must be deployed to worker03

# Let's delete the preferred-node-affinity.yml deployment to proceed with required-node-affinity
oc delete -f preferred-node-affinity.yml

# Let's remove the label from worker03 node
oc label node/worker03.ocp4.palmeto.org disk-
oc get nodes -l disk=ssd

# Let's deploy the required-node-affinity nginx deployment
oc apply -f required-node-affinity.yml
oc get pods -o wide # all pods are supposed to be in Pending as scheduler couldn't find a node that meets your app required criteria

# Label one of the worker node with disk=ssd
oc label node/worker01.ocp4.palmeto.org disk=ssd
oc get pods -o wide # now all your nginx pods should be running in worker01
```

## Lab - Ingress
Note
<pre>
- Ingress is not Service, it is routing(forwarding) set of rules
- In your openshift cluster, depending on which Load Balancer is setup by your Openshift Cluster Administrator, we
  need to use either
  1. HAProxy Ingress Controller or
  2. Nginx Ingress Controller or
  3. F5 Ingress Controller, etc
- Whenever we create an Ingress resource, the Ingress Controller that is active in the cluster will keep monitoring
  for the Ingress resource created in any project within the cluster
- Whenever the Controller detects such a Route, it picks the rules mentioned in the Ingress resource and configures
  a Load Balancer
- HAProxy Ingress Controller only know how to configure a HAProxy Load Balancer
- Nginx Ingress Controller knows only how to configure a Nginx Load Balancer
- It is also important that our Ingress annotation mentions the Ingress Controller that should manage our Ingress
</pre>
