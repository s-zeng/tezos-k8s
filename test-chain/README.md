# Notes on current iteration of testnet

## Storage
- Not using manual storage class for persistent volume. Letting minikube manually provision storage.

## ConfigMap
- Set the bootstrap_peers field in the configMap's config.json to "tezos-p2p:9732". That is the service for the peer to peer network. Allows nodes to find each other.
- The config.json and parameters.json have some required values filled that are populated later by a container in the deployment process.

## Deployment
- Launches a progenitor tezos node which which also will run as a baker.
- Before launching, genesis and baker keys are generated. `kubectl patch` is then run to update the configMap after using `sed` with regex to place the keys in the appropriate spots in the file.

## Role and RoleBinding
- A role and role binding are required in order that a container can run the necessary `kubectl` commands against the k8s api.

## activate-job
- Job waits for the progenitor tezos node to be running using `kubectl wait`. Doing so allows the job containers to access the updated configMap with the dynamically generated keys and run the baker command.

## StatefulSet
- Using a statefulSet to launch tezos peers. Each pod waits for the progenitor node to start which makes sure that the configMap was updated with the dynamically generated keys.
- Multiple pods can be launched at the same time in parallel.
- Each pod gets its own provisioned storage in contrast to how a deployment works where they share the same volumes.
- Pods communicate over the tezos-p2p service on port 9732.
