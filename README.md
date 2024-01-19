# Self-Hosted Azure DevOps Agent on AKS

Azure DevOps requires compute to run pipelines. It can be hosted by Microsoft (as Azure DevOps service bill) or self hosted.

This repo contains the necessary files to deploy a self-hosted Azure DevOps agent on Azure Kubernetes Service (AKS) using a Personal Access Token (PAT)authentication.


[Microsoft guide for Azure DevOps Agent dockerized version](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)

## Dockerfile

The Dockerfile sets up an image based on Ubuntu with several required utilities, as well as the Azure CLI. The Dockerfile creates a new user named "agent", copies a startup script (`start.sh`) into the image, and sets it as the entrypoint.

## Kubernetes Deployment Configuration

The `k8s/devopsagent-deployment.yml` file is a Kubernetes deployment configuration that specifies how to deploy the Docker image on AKS. It defines the necessary resources, such as the number of replicas, the Docker image to use, and the necessary environment variables.

## Startup Script

The `start.sh` file is a shell script that is run when the Docker container is started. It is responsible for starting the Azure DevOps Agent.

## Required Azure configuration


from Azure:

- Azure Container Registry write permissions
- Azure Kubernetes Service admin permissions over namespace used by pipelines.

from Azure DevOps:

- Azure DevOps Agent pool
- Personal Access Token

On Azure Kubernetes Service:

- Kubernetes Namespace for running ADO client
- Write permissions for the user/group owner of PAT on the Kubernetes namespace used by pipelines.
- Kubernetes Rolebinding for the ADO agent service account generated to the namespace used by pipelines.


## ADO Agent Deployment

### Example steps for a ubuntu22 tag

1. Build and tag the image from local
```bash
docker build --no-cache --tag devopsagent:u22 --file ./Dockerfile .

docker tag devopsagent:u22 myazcregistry.azurecr.io/devopsagent:u22
```
2. Login with your Azure account and push the image
```bash
az login --use-device-code

az acr login --name myazcregistry.azurecr.io

docker push myazcregistry.azurecr.io/devopsagent:u22
```
3. Create the kubernetes secret with the PAT
```bash
kubectl create secret generic devops-agent \
  --from-literal=AZP_URL=https://dev.azure.com/yourOrg \
  --from-literal=AZP_TOKEN=YourPAT \
  --from-literal=AZP_POOL=NameOfYourPool
  -n devops
  ```
4. Deploy the replicaset by the deployment file
```bash
kubectl apply -f k8s/devopsagent-deployment.yml -n devops
```

  Once deployed, if the pipelines gonna deploy on a different namespace of self agent, is required allowing permissions to the default service account and for the agent service account generated:

- Example:
```bash
kubectl get serviceaccount -n devops  

NAME              SECRETS   AGE                                                                                     
azdev-sa-a6a8e1   1         7d6h                                                                                   
default           1         17d  
```

```bash
kubectl create rolebinding rolebinding-sa-azdev --role=apps-admin --serviceaccount=devops:azdev-sa-a6a8e1 --serviceaccount=devops:default -n apps
```