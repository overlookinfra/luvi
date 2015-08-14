local daemonize = require("daemonize")

daemonize("/tmp/test.pid", "/tmp/test.log", "sleep", "30")
