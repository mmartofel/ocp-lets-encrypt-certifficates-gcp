## 🌟  Configure Red Hat OpenShift cluster installed at GCP with Let's Encrypt generated certifficates

[![GitHub Repo](https://img.shields.io/badge/GitHub-mmartofel-blue)](https://github.com/mmartofel/ocp-lets-encrypt-certifficates)
[![OpenShift Ready](https://img.shields.io/badge/OpenShift-Ready-brightgreen)](https://www.openshift.com)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---


Small collection of scripts to obtain Let's Encrypt / ZeroSSL certificates using acme.sh and install them into an Red Hat OpenShift cluster.
I built them for GCP as I can easily provision one but I believe thanks to acme.sh portability it can be easily modified for your requirement to work with other providers.

### Quick overview ###

- Install and manage the ACME client: [00-install-let-encrypt-client.sh](00-install-let-encrypt-client.sh)  
- Request certificates (via GCP DNS): [01-request-certifficates.sh](01-request-certifficates.sh)  
- Patch the default OpenShift Ingress controller with the new certificate: [02-patch-default-ingresscontroller.sh](02-patch-default-ingresscontroller.sh)  
- Patch the OpenShift API server serving certs: [03-patch-apiserver.sh](03-patch-apiserver.sh)

### Prerequisites ###

- oc (OpenShift CLI) logged in as cluster-admin
- git, curl, bash
- GCP credentials (service account json file and project ID)

### Enough to run them as follows ###

First login to your cluster with admin credentials copying oc command from OpenShift console or with kubeconfig file.

#### 1. Install/update acme.sh and provide GCP credentials ( ⚠️ beware of two dots in front of a script call here): ####

``` . ./00-install-let-encrypt-client.sh ```

#### 2. Request certificates to find them at 'certificates' directory ####

``` ./01-request-certifficates.sh ```

#### 3. Patch default IngressController of your OpenShift cluster: ####

``` ./02-patch-default-ingresscontroller.sh ```

#### 4. Patch ApiServer of your OpenShift cluster: ####

``` ./03-patch-apiserver.sh ```

Now wait for resources to update and here we go, you have your cluster secured well with Let's Encrypt issued certifficates.

### 🔗 Useful Links ###

Certificate Authority that provides free TLS certificates, making it easy for websites to enable HTTPS encryption and create a more secure Internet for everyone.

- [Let's Encrypt](https://letsencrypt.org/pl/)

A pure Unix shell script ACME client for SSL / TLS certificate automation

- [acme.sh](https://github.com/acmesh-official/acme.sh)

Red Hat OpenShift docummentation

- [OpenShift Documentation](https://docs.openshift.com)