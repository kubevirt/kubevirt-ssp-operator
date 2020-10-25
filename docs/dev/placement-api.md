# Node Placement configuration for Template Validator and Node Labeller

1. The cluster admin can modify the Template Validator/Node Labeller CR to inform what nodes the respective operator pods should be deployed on.
2. Template Validator pods should be placed on nodes that expect infra components

```
# Example TV CR with empty Affinity, Node Selector and Toleration values:

apiVersion: ssp.kubevirt.io/v1
kind: KubevirtTemplateValidator
metadata:
  name: kubevirt-template-validator
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - preference:
            matchExpressions:
              - key: testKey
                operator: In
                values:
                  - testValue
          weight: 1
  nodeSelector:
    testKey: testValue
  tolerations:
  - effect: NoSchedule
    key: testKey
    operator: Exists
```

3. Node Labeller pods should be placed on nodes that expect workload components 

```
# Example NL CR with Affinity, Node Selector and Toleration values:

apiVersion: ssp.kubevirt.io/v1
kind: KubevirtNodeLabellerBundle
metadata:
  name: kubevirt-node-labeller-bundle
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - preference:
            matchExpressions:
              - key: testKey
                operator: In
                values:
                  - testValue
          weight: 1
  nodeSelector:
    testKey: testValue
  tolerations:
  - effect: NoSchedule
    key: testKey
    operator: Exists
```
