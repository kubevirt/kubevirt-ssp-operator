// This file only exists to make sure our API packages compile properly.
package main

import (
	"github.com/kubevirt/kubevirt-ssp-operator/pkg/apis/kubevirt/v1"
)

func main() {
	_ = v1.KubevirtCommonTemplatesBundle{}
}
