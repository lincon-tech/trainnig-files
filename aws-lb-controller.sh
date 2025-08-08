eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster my-first-cluster \
  --approve

eksctl create iamserviceaccount \
  --cluster=my-first-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::YOUR-ACCOUNT:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve