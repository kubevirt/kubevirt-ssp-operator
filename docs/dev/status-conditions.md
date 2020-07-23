# Checking SSP Operator Status conditions

1. Deploy ssp-operator
2. Wait few minutes until all components are deployed
3. run `oc describe KubevirtNodeLabellerBundle`

example output:
```
Name:         kubevirt-node-labeller-bundle
Namespace:    kubevirt
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"kubevirt.io/v1","kind":"KubevirtNodeLabellerBundle","metadata":{"annotations":{},"name":"kubevirt-node-labeller-bundle","namespace":"kub...
API Version:  kubevirt.io/v1
Kind:         KubevirtNodeLabellerBundle
Metadata:
  Creation Timestamp:  2019-08-22T12:21:22Z
  Generation:          1
  Resource Version:    8894
  Self Link:           /apis/kubevirt.io/v1/namespaces/kubevirt/kubevirtnodelabellerbundles/kubevirt-node-labeller-bundle
  UID:                 5a320a2d-c4d7-11e9-95d3-5254006f4280
Spec:
  Version:  v0.0.5
Status:
  Conditions:
    Last Transition Time:  2019-08-22T12:23:01Z
    Message:               Node-labeller is progressing.
    Reason:                progressing
    Status:                False
    Type:                  Progressing
    Last Transition Time:  2019-08-22T12:22:37Z
    Message:               Node-labeller is available.
    Reason:                available
    Status:                True
    Type:                  Available
    Last Transition Time:  2019-08-22T12:22:37Z
    Message:               Node-labeller is degraded.
    Reason:                degraded
    Status:                False
    Type:                  Degraded
    Ansible Result:
      Changed:             0
      Completion:          2019-08-22T12:25:33.424451
      Failures:            0
      Ok:                  8
      Skipped:             0
    Last Transition Time:  2019-08-22T12:21:29Z
    Message:               Awaiting next reconciliation
    Reason:                Successful
    Status:                True
    Type:                  Running
Events:                    <none>
```

4. check status.conditions - it should contain conditions:
```
Progressing - False
Available - True
Degraded - False
```

5. the same you can do with KubevirtTemplateValidator and KubevirtCommonTemplatesBundle (this CR will NOT contain degraded condition, because it makes no sense to put it there, because in every iteration templates are "reinstalled")

6. you can of course delete pods and test if it changes conditions (but take in account, every iteration is slow, so when you delete e.g. node-labeller, it can be recreated between the iterations and ansible will not notice that it was deleted).
The Easiest way is to create e.g. 2 nodes, let node-labeller to be deployed on both nodes and then disable one (`sudo ifconfig eth0 down && sleep 10 && sudo ifconfig eth0 up`)
and then wait for [300x10 second](https://github.com/kubevirt/kubevirt-ssp-operator/pull/76/files#diff-d1fae8c4046ebdb431e9b097881fc1b7R39 I think we should lower this constant) after that it should set conditions:
```
Progressing - True
Available - False
Degraded - True
```
