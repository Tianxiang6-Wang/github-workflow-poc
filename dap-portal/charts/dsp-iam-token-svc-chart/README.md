# HZP IAM Token Helm Chart

## Prerequisites

### Kubernetes and Helm

* On Windows, install https://rancherdesktop.io/. It comes with WSL, K3s and Helm. If you already have WSL or Docker Desktop,
  it is recommended to uninstall all first.
* On Linux, install https://k3s.io/ and https://helm.sh/

## Make

Download and install http://gnuwin32.sourceforge.net/packages/make.htm

## Configuration

Please refer to [Configuration](../../../../../README.md#configuration) for configuration set up.

## Installation
> __Note:__ Installation & Uninstallation capability has been moved. Please refer to the Readme file under hzp-eo-charts.

## Check
Check the running pods with:
```
kubectl get po
```

List all helm chart releases with:
```
helm list
```