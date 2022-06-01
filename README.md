# myproxy terraform
## Description
Building eks using terraform and introducing argoCD  

![eks_net drawio](https://user-images.githubusercontent.com/35088230/171386622-c6a5a931-aa06-4248-b761-2e78838aa778.png)

## Setup

### aws cli
Installation of awscli  
```bash
$ brew install awscli
```

create profile  
```bash
$ aws configure --profile user1
```

```
 AWS Access Key ID [None]: {アクセスキー(各自)}
 AWS Secret Access Key [None]: {シークレットアクセスキー(各自)}
 Default region name [None]: ap-northeast-1
 Default output format [None]: json
```
You need to switch to this user when accessing the command line, so check with the following command each time  
```bash
$ aws configure list
```

### kubectl install 
CLI installation for EKS master node access  
```bash
$ brew install kubectl
```

### Creating credentialed files  

```bash
cd ./dev/
touch terraform.tfvars
```

Write the necessary information in the credential file  

```
#terraform.tfvars

aws_access_key = "{アクセスキー(各自)}"
aws_secret_key = "{シークレットアクセスキー(各自)}"

```
### terraform.tfvars
#### aws token
Create an access token in aws "aws_access_key" and "aws_secret_key  


## construction

```bash
terraform init
terraform paln
terraform apply
```

### init
```bash
terraform init
```

### Configuration Confirmation
```bash
terraform plan
```

### Construction
```bash
terraform apply
```

### Confirmation of deletion
```bash
terraform plan -destroy
```

### Construct Deletion
```bash
terraform destroy
```

## Configure access permissions to the EKS control plane
As the output of Terraform, a ConfigMap named aws-auth is set up, so output it to an arbitrary YAML file.  
```bash
$ terraform output aws_auth_config_map > aws-auth-configmal.yaml
```

Edit this file and add any IAM user (remove the first (EOT) and last (EOT) from the output).  

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::xxxxxxxxxxx:role/test_node-eks-node-group-xxxxxxxxxxxxxxxxxx
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  # 以下を追加
  mapUsers: |
    - userarn: arn:aws:iam::xxxxxxxxxxx:user/xxxxxx
      username: xxxxxx
      groups:
        - system:masters
```

Add a mapUsers section as above, specifying the ARN of the IAM user for developers as userarn and the corresponding username as username.  
As before, we have specified system:masters for administrative privileges, but review the privileges as necessary.  

Update the kubectl connection settings (kubeconfig) for the current Terraform user.  
```bash
$ aws eks update-kubeconfig --name test-k8s
```

update configmap  
```bash
$ kubectl apply -f aws-auth-configmal.yaml
```

Let's access the EKS cluster.  
```bash
$ kubectl cluster-info
```

If the cluster information is output as follows, the configuration is complete.  
```
Kubernetes control plane is running at https://xxxxxxxxxxxxxxxxxxx.sk1.ap-northeast-1.eks.amazonaws.com
CoreDNS is running at https://xxxxxxxxxxxxxxxxxxxxxxxx.sk1.ap-northeast-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

## argoCD setup
First, create a Namespace to run the Argo CD resources.
```bash
$ kubectl create namespace argocd
```

Once the Namespace is created, the next step is to create a Pod.  
The manifest is from the GitHub of the Argo CD.  
```bash
$ kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

After the manifest is applied, check if the pod is created.  
```bash
$ kubectl get pod -n argocd
```

Access to GUI screen  
```bash
$ kubectl port-forward svc/argocd-server -n argocd 8080:443
```
If you port-forward the argocd-server service like this, you can access the GUI screen.  
https://localhost:8080  

### argoCD login
Username:admin  
Password:  Retrieved by the following command
```bash
$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -D; echo
```

## delete resors
delete pod  
```bash
$ kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

delete eks  
```bash
$ terraform destroy
```

