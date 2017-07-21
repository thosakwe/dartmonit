# dartmonit
Monitor Dart scripts, and run them on startup. This is very early in the development stages, so expect some changes.

# Installation
```bash
pub global activate dartmonit
```

To add a script to `/etc/init.d`:
```bash
dartmonit install
```

# Usage
dartmonit is essentially an HTTP server,
which runs as a daemon and exposes a simple API.

Most of the CLI commands query a running API.

To manually start the server (not as a daemon):
```bash
dartmonit start
dartmonit start --port 2245
```

`2245` is the default port.

On Ubuntu, you can run it as a service...

```bash
sudo service dartmonit start
```

# Commands

```
Usage: dartmonit <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  help      Display help information for dartmonit.
  install   Adds a shell script to /etc/init.d to run dartmonit on startup.
  kill      Halts the execution of a given command.
  run       Spawns a child process at the given absolute path.
  start     Starts the dartmonit HTTP server.
  status    Fetches the status of a given process.
  stop      Instructs an active dartmonit server to shut down.

Run "dartmonit help <command>" for more information about a command.
```

# API
TODO: API documentation