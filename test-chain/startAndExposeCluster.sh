#!/bin/bash

set -e

#####
# https://minikube.sigs.k8s.io/docs/tutorials/nginx_tcp_udp_ingress/

# Enable minikube ingress nginx addon
minikube addons enable ingress

# Add tezos-p2p TCP service to the nginx ingress controller configmap
kubectl patch configmap tcp-services -n kube-system --patch '{"data":{"9732":"tqtezos1/tezos-p2p:9732"}}'

# Make nginx ingress controller listen for TCP traffic to forward to tezos-p2p service
kubectl -n kube-system patch deployment ingress-nginx-controller \
--patch "
spec:
  template:
    spec:
      containers:
      - name: controller
        ports:
         - containerPort: 9732
           hostPort: 9732
"

printf "Configured ingress for TCP traffic on port 9732.\n"
#####

DIRNAME=$(dirname ${BASH_SOURCE[0]})

# If there is a tezos cluster already running, get the nodes's name and namespace
NODE_NAME=$(kubectl get pods -A -l app=tezos-node -o name)

if [ -z "$NODE_NAME" ]
then
  printf "\nStarting Tezos cluster...\n"
  kubectl apply -f "$DIRNAME/testnet.yml"

  printf "\nWaiting for genesis key...\n"
  NODE_NAME=$(kubectl get pods -A -l app=tezos-node -o name)
  NODE_NAMESPACE=$(kubectl get pods -A -l app=tezos-node -o jsonpath='{.items[0].metadata.namespace}')
  # Wait for boostrap_node to spin up which creates the genesis key
  kubectl wait --for=condition=Ready $NODE_NAME --timeout=30s -n $NODE_NAMESPACE
else
  printf "\nTezos cluster is already running.\n"
  NODE_NAMESPACE=$(kubectl get pods -A -l app=tezos-node -o jsonpath='{.items[0].metadata.namespace}')
fi

GENESIS_PUBKEY=$(kubectl get cm -n $NODE_NAMESPACE tezos-config -o json \
  | jq '.data."config.json" | fromjson | .network.genesis_parameters.values.genesis_pubkey'
)
printf "\nGENESIS_PUBKEY: $GENESIS_PUBKEY"
printf "\nAdding tezos node's genesis_pubkey to ConfigMap in peerCluster.yml..."
sed -Ei '' "s/(\"genesis_pubkey\": *)\".*\"/\1$GENESIS_PUBKEY/" "$DIRNAME/peerCluster.yml"
printf "\nPlease confirm ConfigMap's genesis_pubkey field is correct.\n"

# Get machines local ip address
unameOut=$(uname)
case $unameOut in
  Linux*)  IP=$(hostname -i);;
  Darwin*) IP=$(ipconfig getifaddr en1 || ipconfig getifaddr en0);;
  *)       printf "\nCould not get your machines local ip.\nManually run port-forwarding: kubectl port-forward -n kube-system deployment/ingress-nginx-controller 9732 8732:80 --address YOUR_IP_HERE\n"
esac


if [ -n "$IP" ]
then
  # Add machine's ip and genesis_pubkey to config map of ./peerCluster.yml
  printf "\nAdding your machine's ip to ConfigMap's boostrap-peers field in peerCluster.yml..."
  sed -Ei '' "s/YOUR_MACHINES_IP/$IP/" "$DIRNAME/peerCluster.yml"
  printf "\nPlease confirm ConfigMap's boostrap-peers field has your ip.\n"

  printf "\nStarting port forwarding...\n"
  # Port forward to nginx ingress on your local machine
  # kubectl wait --for=condition=Available deployment/ingress-nginx-controller --timeout=30s -n kube-system
  kubectl port-forward -n kube-system deployment/ingress-nginx-controller 9732 8732:80 --address $IP
fi
