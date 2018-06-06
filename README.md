# dev-infra

A simple wrapper around [Docker Compose](https://docs.docker.com/compose/) to easily manage various infrastructure tools that I use for development.

## How to install?

1. Clone this repo
2. Add the repo to your path

Pull this repo as often as you'd like to look for new tools.

## How to use

`infra.sh <goal> <service>`

Valid goals:
```
Ignores services:
  list          List available tools
  pull          Pull associated containers for all tools

Requires a service to be specified:
  start         Start a service
  stop          Stop a service
  restart       Restart a service
  status        Outputs whether a service is running or not
  tail          Tail log output from a service
```

## How to add a custom service?

Create a custom Docker Compose file in the `infra` directory and give it a meaningful name.
