# CentOS minimal base image

CentOS base image containing only essential components.

**Table of Contents** 

- [CentOS minimal base image](#centos-minimal-base-image)
  - [Requirements](#requirements)
  - [Image contents](#image-contents)
  - [Building the image](#building-the-image)
  - [Stopping the container](#stopping-the-container)
  - [About SSH](#about-ssh)
    - [Using your own SSH key](#using-your-own-ssh-key)
    - [Generate new SSH key](#generate-new-ssh-key)

## Requirements

* Rinse. For installing RPM-based distribution. 
* Operating system: the following scripts have been tested on Debian based systems such as:
    * Ubuntu >= 14.04
    * Debian >= 8.0 

## Image contents

- [x] CentOS 6 (last available)
- [x] Upstart init system
- [x] SSH server 
- [x] EPEL repository enabled
- [x] Default locale set to `en_US.utf8`
- [x] Extra utilities: tree less nano curl tar gzip unzip ncurses-base which
- [x] SELinux disabled
- [x] Trigger an immediate shutdown when upstart receives SIGPWR. Find [here](https://github.com/Bitergia/docker/blob/master/baseimages/centos/shutdown.conf) the script
- [x] Non root user `bitergia` with `sudo` privileges (needed for SSH access)

## Building the image

For building the image yourself, you will need to use `sudo` to execute it (needed for rinse).

Clone this repository:

```
git clone https://github.com/Bitergia/docker.git
cd docker/baseimages
```
[Optional] Remove pre-generated SSH keys:

```
rm bitergia-docker bitergia-docker.pub
```
This will force the generation of a new ssh keypair.

Build the image:

```
sudo make centos
```

And that's it!

## Stopping the container

`docker stop` sends SIGTERM to the init process, which is then supposed to stop all services. Unfortunately most init systems don't do this correctly within Docker since they're built for hardware shutdowns instead. This causes processes to be hard killed with SIGKILL, which doesn't give them a chance to correctly clean-up things.

To avoid this, we suggest to use the [docker-stop](https://github.com/Bitergia/docker/tree/master/utils#docker-stop) script available in this [repository](https://github.com/Bitergia/docker/tree/master/utils). This script basically sends the SIGPWR signal to /sbin/init inside the container, triggering the shutdown process and allowing the running services to cleanly shutdown.

## About SSH

SSH is enabled by default with a pre-generated insecure SSH key copied into your `.ssh` folder. Once a container is up, you can access the container easily by using our own [docker-ssh](https://github.com/Bitergia/docker/tree/master/utils#docker-ssh) script:

```
docker-ssh bitergia@<container-id>
```

Or you can just use the old-fashioned way to access a docker container: 

```
ssh bitergia@<container-ip>
```

Container IP can be retrieved using the following command:

```
docker inspect -f "{{ .NetworkSettings.IPAddress }}" <container-id>
```

You can also use the [get-container-ip](https://github.com/Bitergia/docker/tree/master/utils#get-container-ip) script provided in this repository. 

### Using your own SSH key

If you would like to use your own ssh-key, you just need to place your `.pub` key in the following folder just before building your image. **Note** that the key must be renamed as `bitergia-docker.pub`:

```
docker/baseimages
```
### Generate new SSH key

You can always create a new SSH insecure key. You just need to remove the `bitergia-docker` and `bitergia-docker.pub` files and use the [Makefile](https://github.com/Bitergia/docker/blob/master/baseimages/Makefile#L49) again to generate your image.


