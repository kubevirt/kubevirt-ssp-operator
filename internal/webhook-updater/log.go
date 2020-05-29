package webhook_updater

import "log"

// TODO -- use structural logging, similar to SSP operator
type simpleLogger struct {
}

func (l *simpleLogger) Errorf(format string, args ...interface{}) {
	log.Printf("[ERROR] "+format, args)
}

func (l *simpleLogger) Info(message string) {
	log.Print("[INFO] " + message)
}

func (l *simpleLogger) Infof(format string, args ...interface{}) {
	log.Printf("[INFO] "+format, args)
}

var Log = &simpleLogger{}
