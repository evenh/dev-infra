# dev-infra [![Build Status](https://travis-ci.org/evenh/dev-infra.svg?branch=master)](https://travis-ci.org/evenh/dev-infra)

A simple wrapper around [Docker Compose](https://docs.docker.com/compose/) to easily manage various infrastructure tools that I use for development.

## How to install?

1. Clone this repo
2. Add the repo to your path
3. (Optional) Add an alias for `infra.sh`, such as `infra`

Pull this repo as often as you'd like to look for new tools.

## How to use

`infra.sh <goal> <service>`

Valid goals:
```
Ignores services:
  list          List available tools
  pull          Pull associated containers for all tools
  ps            List running containers

Requires a service to be specified:
  start         Start a service
  stop          Stop a service
  restart       Restart a service
  status        Outputs whether a service is running or not
  tail          Tail log output from a service
```


### A note on Windows compatibility

For Windows, named volumes are used instead of host mounted folders (because of issues with Windows..). This means that when trying to start a service you will see a message like this:

> Volume infra-servicename declared as external, but could not be found. Please create the volume manually using `docker volume create --name=infra-servicename` and try again.

In that case, just execute that command and carry on - volume handling is not handled by this script.

## How to add a custom service?

Create a custom Docker Compose file in the `tools` directory and give it a meaningful name. If you use volumes, please also do add a `.win.yml` override definition as it will be automatically be picked up by this script.
