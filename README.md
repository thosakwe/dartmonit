# dartmon
Monitor Dart scripts, and run them on startup. This is very early in the development stages, so expect some changes.

# Installation
```bash
pub global activate dartmon
```

To add a script to `/etc/init.d`:
```bash
dartmon install
```

# Usage
Dartmon is essentially an HTTP server,
which runs as a daemon and exposes a simple API.

Most of the CLI commands query a running API.

To manually start the server (not as a daemon):
```bash
dartmon start
dartmon start --port 2245
```

`2245` is the default port.

On Ubuntu, you can run it as a service...

```bash
sudo service dartmon start
```

# Commands

```
Usage: dartmon <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  help      Display help information for dartmon.
  install   Adds a shell script to /etc/init.d to run dartmon on startup.
  kill      Halts the execution of a given command.
  run       Spawns a child process at the given absolute path.
  start     Starts the dartmon HTTP server.
  status    Fetches the status of a given process.
  stop      Instructs an active dartmon server to shut down.

Run "dartmon help <command>" for more information about a command.
```

# API
TODO: API documentation