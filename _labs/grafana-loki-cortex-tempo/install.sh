# /bin/bash
minikube start -p observ --cpus=4 --disk-size='50000mb' --nodes=3 --disable-driver-mounts

#install the metrics server in your cluster
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl top nodes 
kubectl top po --all-namespaces

kubectl create ns observability
kubectl get ns

# INGRES
helm repo add nginx-stable https://helm.nginx.com/stable
helm install -n nginx my-release nginx-stable/nginx-ingress --create-namespace

# LOKI
cd grafana/helm-charts/charts/loki-stack/
helm dependencies update
helm install loki . --namespace observability

# TEMPO
# cd ../tempo

# helm install tempo . --namespace observability

# ETCD
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install etcd-release bitnami/etcd -n etcd --create-namespace

# ** Please be patient while the chart is being deployed **

# etcd can be accessed via port 2379 on the following DNS name from within your cluster:

#     etcd-release.default.svc.cluster.local

# To create a pod that you can use as a etcd client run the following command:

#     kubectl run etcd-release-client --restart='Never' --image docker.io/bitnami/etcd:3.5.4-debian-11-r31 --env ROOT_PASSWORD=$(kubectl get secret --namespace default etcd-release -o jsonpath="{.data.etcd-root-password}" | base64 -d) --env 
# ETCDCTL_ENDPOINTS="etcd-release.default.svc.cluster.local:2379" --namespace default --command -- sleep infinity

# Then, you can set/get a key using the commands below:

#     kubectl exec --namespace default -it etcd-release-client -- bash
#     etcdctl --user root:$ROOT_PASSWORD put /message Hello
#     etcdctl --user root:$ROOT_PASSWORD get /message

# To connect to your etcd server from outside the cluster execute the following commands:

#     kubectl port-forward --namespace default svc/etcd-release 2379:2379 &
#     echo "etcd URL: http://127.0.0.1:2379"

#  * As rbac is enabled you should add the flag `--user root:$ETCD_ROOT_PASSWORD` to the etcdctl commands. Use the command below to export the password:

#     export ETCD_ROOT_PASSWORD=$(kubectl get secret --namespace default etcd-release -o jsonpath="{.data.etcd-root-password}" | base64 -d)

#MINIO
helm repo remove minio
helm repo add minio https://charts.min.io/
helm install --namespace minio --set rootUser=rootuser,rootPassword=rootpass123 --set persistence.enabled=false --generate-name minio/minio --create-namespace --set replicas=3

#MIMIR
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install mimir-dev grafana/mimir-distributed -n mimir --create-namespace
# CORTEX
# helm repo add cortex-helm https://cortexproject.github.io/cortex-helm-chart

# helm install cortex --namespace cortex cortex-helm/cortex --create-namespace

# # Verify the application is working by running these commands:
# #   kubectl --namespace cortex port-forward service/cortex-querier 8080
# #   curl http://127.0.0.1:8080/services