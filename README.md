## Bitergia docker repository

Bitergia docker repository contains a set of baseimages and tools to be used with [Docker](https://github.com/docker/docker).

Baseimages are already built and available at [Bitergia Dockerhub](https://registry.hub.docker.com/repos/bitergia).

**Table of Contents**

- [Baseimages](#baseimages)
- [Utils](#utils)

## Baseimages

Available images:

* [CentOS 6](https://github.com/Bitergia/docker/tree/master/baseimages/centos)
* [Ubuntu Trusty 14.04.2](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu)

## Utils

We've created a set of utilities and useful scripts for handling docker images. All those utilities and its usage is available [here](https://github.com/Bitergia/docker/tree/master/utils).

Here's a brief description on what this tools can do for you:

* `docker-stop` Sends the SIGPWR signal to /sbin/init inside the container. We hardly encourage the usage of this script, as it allows the running services to cleanly shutdown avoiding issues.
* `docker-ssh` Helps using ssh to log into a running container.
* `docker-scp` Helps using scp to transfer files from/to a running container with a running ssh daemon.
* `get-container-ip` Helper script to obtain the IP address of a running container.
* `get-docker-hosts` Helper script to add the running containers to /etc/hosts or update the existing info.
