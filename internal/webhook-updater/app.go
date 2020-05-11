package webhook_updater

import (
	"errors"
	"os"
	"os/signal"
	"sync"
	"syscall"

	flag "github.com/spf13/pflag"
)

type App struct {
	kubeconfig string
	port       int

	client      ClientProxy
	updater     *CertUpdater
	updaterLock sync.Mutex
}

func (app *App) Run() {
	err := app.parseAndValidateFlags()
	if err != nil {
		Log.Errorf("%s", err)
		os.Exit(1)
	}

	app.client, err = NewClientProxy(app.kubeconfig)
	if err != nil {
		Log.Errorf("Error creating kubernetes client: %s", err)
		os.Exit(1)
	}

	defer app.cleanup()

	service := &Service{Port: app.port, CertUpdaterHandler: app.handleCertUpdater}
	registerSignalHandler(func() { service.Close() })

	Log.Info("Starting server.")
	err = service.Listen()
	if err != nil {
		Log.Errorf("Server listen failed: %s", err)
		os.Exit(1)
	}
}

func (app *App) parseAndValidateFlags() error {
	flag.IntVarP(&app.port, "port", "p", 80, "port on which the process listens to commands (default 80)")
	flag.StringVarP(&app.kubeconfig, "kubeconfig", "c", "", "absolute path to the kubeconfig file")
	flag.Parse()

	if app.kubeconfig != "" {
		stat, err := os.Stat(app.kubeconfig)
		if err != nil {
			return err
		}
		if stat.IsDir() {
			return errors.New("kubeconfig does not point to a file")
		}
	}

	return nil
}

func registerSignalHandler(handler func()) {
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-signalChannel
		handler()
	}()
}

func (app *App) cleanup() {
	app.updaterLock.Lock()
	defer app.updaterLock.Unlock()
	if app.updater != nil {
		app.updater.Stop()
		app.updater = nil
	}
}

func (app *App) handleCertUpdater(certUpdater *CertUpdater) error {
	err := certUpdater.Validate(app.client)
	if err != nil {
		return err
	}

	app.updaterLock.Lock()
	defer app.updaterLock.Unlock()

	if app.updater != nil {
		Log.Infof("Stopping CaBundle update for webhook: %s", app.updater.Webhook)
		app.updater.Stop()
		app.updater = nil
	}

	app.updater = certUpdater
	Log.Infof("Starting CaBundle update for webhook: %s", certUpdater.Webhook)
	return app.updater.Start(app.client)
}
