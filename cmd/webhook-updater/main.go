package main

import webhook_updater "github.com/MarSik/kubevirt-ssp-operator/internal/webhook-updater"

func main() {
	app := webhook_updater.App{}
	app.Run()
}
