There are two was of deploying to the Cluster in this folder:




A: Deploy via Kubectl

Gerneral preparation:
1) Run "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/mandatory.yaml"
2) Run "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/aws/service-nlb.yaml"
3) Run "kubectl apply -f deployment.yaml"
4) Run "kubectl apply -f service.yaml"
5) Run "kubectl apply -f ingress.yaml"
6) Get the IP of the LoadBalancer via "kubectl get svc -n ingress-nginx ingress-nginx -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'"




B: Deploy via Terraform

1) Run "terraform apply"