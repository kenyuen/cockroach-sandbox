# CockroachDB Kubernetes Layout

This directory mirrors the six-node, east/west split local cluster previously defined in `docker-compose.yml` and provides the Kubernetes artifacts needed to run the same topology.

## What is here
- `cockroach-scripts-configmap.yaml` keeps the startup and init shell scripts, including locality derivation, validation, and TODOs highlighting the security gaps (e.g., TLS/certs, secrets handling).
- `cockroach-services.yaml` exposes dedicated headless Services for east and west regional StatefulSets plus a ClusterIP Service that behaves like the HAProxy proxy for SQL/UI access inside the cluster.
- `cockroach-statefulsets.yaml` deploys two StatefulSets (east/west) with three replicas each, mountable PVCs, the shared scripts ConfigMap, Prometheus scraping annotations, and readiness probes that match the compose healthchecks.
- `cockroach-init-job.yaml` runs the init script once against `cockroach-east-0` so the cluster is initialized the same way the compose init service did.

## Running locally
1. Ensure your `KUBECONFIG` or current context targets a cluster with a default StorageClass (or adjust the `volumeClaimTemplates` with the correct `storageClassName`).
2. Apply the manifests:
```bash
kubectl apply -f k8s/
```
3. Wait for the StatefulSets to roll out and PVCs to bind:
```bash
kubectl rollout status statefulset/cockroach-east
kubectl rollout status statefulset/cockroach-west
```
4. Run the init job (idempotent) to bootstrap the cluster schema:
```bash
kubectl apply -f k8s/cockroach-init-job.yaml
kubectl wait --for=condition=complete job/cockroach-init --timeout=120s
```
5. Confirm all CockroachDB pods are ready and part of the same cluster:
```bash
kubectl get pods -l app=cockroach
kubectl port-forward service/cockroach-sql-ui 26257:26257 8080:8080
# In a new shell, run inside any pod to view node status
kubectl exec cockroach-east-0 -- /cockroach/cockroach node status --insecure
```

## Next steps / TODOs
- Inject TLS certificates via Secrets and switch scripts to `--certs-dir`/`--ca-cert` so the cluster runs securely instead of `--insecure`.
- Replace the ClusterIP Service with an Ingress or LoadBalancer and keep the HAProxy proxy logic if you need custom routing.
- Document CI/CD deployment steps that apply these manifests plus `kubectl wait`/`kubectl rollout status` checks before the cluster is considered ready.
- Consider adding a `kustomization.yaml` or Helm wrapper if you want overlays for prod vs dev locality or storage classes.

