# Day 42 - Hosting a Local Docker Container Registry on Kubernetes (CKA 2024)

Video: https://www.youtube.com/watch?v=Py-vsaD0WT4

## Overview

This is the last video of the CKA 2024 series. The project involves hosting a Docker container registry locally as a container on Kubernetes using the CNCF project called **Distribution Registry**. It implements TLS, authentication, secrets, deployments, replicas, services, and persistent storage.

### Why not DockerHub?

Using DockerHub as a container registry is not a best practice for production because it's publicly available. Alternatives include:
- **Public:** DockerHub, Quay.io, GitHub Packages
- **Cloud:** AWS ECR, Azure ACR, Google GCR/Artifact Registry, IBM Cloud Container Registry
- **Enterprise self-hosted:** Sonatype Nexus, JFrog Artifactory

### Simple (non-production) way

```bash
docker run -d -p 5000:5000 registry:2
```

This lacks persistent storage, TLS, authentication, HA, and fault tolerance — not suitable for production.

---

## Terminal Session 1: Setup directories and generate TLS certificates

```bash
# Verify cluster is ready
kubectl get nodes

# Create directory structure
mkdir -p registry/certs
mkdir -p registry/auth

# Generate self-signed TLS certificate
openssl req -x509 -newkey rsa:4096 -days 365 -nodes \
  -keyout registry/certs/tls.key \
  -out registry/certs/tls.crt \
  -subj "/CN=my-registry" \
  -addext "subjectAltName=DNS:my-registry"
```

---

## Terminal Session 2: Generate authentication credentials

```bash
# Generate htpasswd file using httpd container
docker run --entrypoint htpasswd httpd:2 -Bbn myuser mypasswd > registry/auth/htpasswd

# Verify
cat registry/auth/htpasswd
```

---

## Terminal Session 3: Create Kubernetes secrets

```bash
# Create TLS secret
kubectl create secret tls certs-secret \
  --cert=registry/certs/tls.crt \
  --key=registry/certs/tls.key

# Create authentication secret (generic/opaque)
kubectl create secret generic auth-secret \
  --from-file=registry/auth/htpasswd

# Verify secrets
kubectl get secrets
kubectl describe secret certs-secret
```

---

## Terminal Session 4: Create Persistent Volume and PVC

```bash
# Create the host path directory
mkdir -p /home/ubuntu/repos
```

### volume.yaml

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: registry-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /home/ubuntu/repos
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

```bash
# Clean up any existing PV/PVC
kubectl delete pvc registry-pvc
kubectl delete pv registry-pv

# Apply
kubectl apply -f volume.yaml

# Verify
kubectl get pv
kubectl get pvc
```

---

## Terminal Session 5: Deploy the registry

### deploy.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: registry
spec:
  replicas: 2
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
        - name: registry
          image: registry:2.8.2
          ports:
            - containerPort: 5000
          volumeMounts:
            - name: repo-volume
              mountPath: /var/lib/registry
            - name: certs-volume
              mountPath: /certs
              readOnly: true
            - name: auth-volume
              mountPath: /auth
              readOnly: true
          env:
            - name: REGISTRY_HTTP_TLS_CERTIFICATE
              value: /certs/tls.crt
            - name: REGISTRY_HTTP_TLS_KEY
              value: /certs/tls.key
            - name: REGISTRY_AUTH
              value: htpasswd
            - name: REGISTRY_AUTH_HTPASSWD_REALM
              value: "Registry Realm"
            - name: REGISTRY_AUTH_HTPASSWD_PATH
              value: /auth/htpasswd
      volumes:
        - name: repo-volume
          persistentVolumeClaim:
            claimName: registry-pvc
        - name: certs-volume
          secret:
            secretName: certs-secret
        - name: auth-volume
          secret:
            secretName: auth-secret
```

```bash
kubectl apply -f deploy.yaml
kubectl get pods
```

---

## Terminal Session 6: Expose the registry as a service

### service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
spec:
  selector:
    app: registry
  ports:
    - protocol: TCP
      port: 5000
      targetPort: 5000
  type: NodePort
```

```bash
kubectl apply -f service.yaml
kubectl get svc
kubectl describe svc docker-registry
kubectl get pods -o wide
```

---

## Terminal Session 7: Configure DNS and environment variables

```bash
# Export environment variables
export REGISTRY_NAME="my-registry"
export REGISTRY_IP=$(kubectl get svc docker-registry -o jsonpath='{.spec.clusterIP}')

# Add entry to /etc/hosts on ALL nodes (control plane + workers)
sudo sh -c "echo '${REGISTRY_IP} my-registry' >> /etc/hosts"
```

---

## Terminal Session 8: Trust self-signed certificates on all nodes

```bash
# On ALL nodes: copy the TLS cert to the system CA store
sudo cp registry/certs/tls.crt /usr/local/share/ca-certificates/tls.crt
sudo update-ca-certificates

# On ALL nodes: configure Docker to trust the registry cert
sudo mkdir -p /etc/docker/certs.d/my-registry:5000
sudo cp registry/certs/tls.crt /etc/docker/certs.d/my-registry:5000/ca.crt
```

---

## Terminal Session 9: Docker login and push an image

```bash
# Login to the private registry
docker login my-registry:5000 -u myuser -p mypasswd

# Pull a sample image
docker pull nginx

# Tag it for the private registry
docker tag nginx:latest my-registry:5000/my-nginx:v2

# Push to the private registry
docker push my-registry:5000/my-nginx:v2
```

---

## Terminal Session 10: Verify image inside the registry pod

```bash
# Exec into a registry pod
kubectl exec -it <registry-pod-name> -- sh

# Inside the pod, verify the stored image
ls /var/lib/registry/docker/registry/v2/repositories/
# Should show: my-nginx

exit
```

---

## Terminal Session 11: Pull image in a pod using imagePullSecrets

### Create Docker registry secret

```bash
kubectl create secret docker-registry nginx-secret \
  --docker-server=my-registry:5000 \
  --docker-username=myuser \
  --docker-password=mypasswd
```

### new.yaml (Pod using private registry image)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
    - name: nginx
      image: my-registry:5000/my-nginx:v2
      ports:
        - containerPort: 80
  imagePullSecrets:
    - name: nginx-secret
```

```bash
kubectl apply -f new.yaml
kubectl get pods

# Verify nginx is serving
kubectl get pod nginx-pod -o wide
curl http://<POD_IP>
# Should show: Welcome to nginx!
```

---

## Key Takeaways

- Always use **persistent storage** for container registries
- Use **TLS certificates** for secure communication
- Use **htpasswd authentication** to protect the registry
- Mount secrets as **volumes** (not environment variables) — best practice
- Use **imagePullSecrets** when pulling from private registries in Kubernetes
- Add registry DNS entries to `/etc/hosts` on all nodes when not using a real domain
- Trust self-signed certs both at the **OS level** and in **Docker's cert store**
