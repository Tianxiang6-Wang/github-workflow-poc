# Introduction 
NATS (open-source messaging system) chart standalone

# Please read about exposing nats externally

https://confluence.cec.lab.emc.com/display/ISGPDE/Exposing+NATS+Externally

# Getting Started
## Install
```sh
$ cd helm
$ helm upgrade --install dsp-portal-nats -n NAMESPACE .
```

### Check
```sh
$ helm list -n NAMESPACE
NAME                            NAMESPACE                       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
dsp-portal-nats                 dsp-portal-usr-dingd-test-pg    1               2025-02-07 14:07:32.1755759 +0800 CST   deployed        nats-0.1.0                              1.16.0

$ kubectl get pods -n NAMESPACE
NAME                                      READY   STATUS    RESTARTS   AGE
nats-jetstream-0                          1/1     Running   0          3m52s
```

## Uninstall
```sh
$ helm uninstall dsp-portal-nats  -n NAMESPACE
```
