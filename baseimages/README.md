## Bitergia base images repository

Available images:

* [CentOS 6](https://github.com/Bitergia/docker/tree/master/baseimages/centos)
* [Ubuntu Trusty 14.04.2](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu)

This images are intended for Docker usage. Images are already built at [Bitergia dockerhub](https://registry.hub.docker.com/repos/bitergia).

Still, if you want to build the entire image yourself, you can use the `Makefile` provided in this folder. 

You can build Ubuntu image doing:

```
sudo make ubuntu
```

Or CentOS one same way:

```
sudo make centos
```

## SSH insecure keys

By default, SSH insecure keys are provided with the images. Everytime you would like to access a container based on one of this images through SSH, you will need to use them. Find detailed information on how to access or change them [here](https://github.com/Bitergia/docker/tree/master/baseimages/ubuntu).

