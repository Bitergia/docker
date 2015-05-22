insecure-ssh-key = bitergia-docker
public-insecure-ssh-key = bitergia-docker.pub

.PHONY: help
help:
	$(info )
	$(info This makefile will help you build docker baseimages from scratch with a)
	$(info few modifications to be able to run /sbin/init and a ssh server inside)
	$(info the container.)
	$(info )
	$(info Available options:)
	$(info )
	$(info - all:					Build all available images)
	$(info - ssh_generate_insecure_key:		Generate a passwordless ssh key)
	$(info )
	$(info Available images:)
	$(info )
	$(info - centos:				Build centos 6 image)
	$(info - ubuntu:				Build ubuntu trusty image)
	$(info )
	$(info To build the images on a Debian/Ubuntu based OS, you will need:)
	$(info )
	$(info - debootstrap, to build the ubuntu image)
	$(info - rinse, to build the centos image)
	$(info - sudo, to be able to execute the above commands)
	$(info )
	$(info Examples:)
	$(info )
	$(info - Generate an insecure ssh key to use with the images: make ssh_generate_insecure_key)
	$(info - Generate a CentOS 6 docker image: sudo make centos)
	$(info - Generate an Ubuntu 14.04.x LTS docker image: sudo make ubuntu)
	$(info )
	@echo ""

.PHONY: centos ubuntu
centos ubuntu: $(public-insecure-ssh-key) $@
	cp -f $(public-insecure-ssh-key) $@/
	$(MAKE) -C $@
	rm -f $@/$(public-insecure-ssh-key)

.PHONY: all
all: centos ubuntu

$(public-insecure-ssh-key): $(insecure-ssh-key)

$(insecure-ssh-key):
	@$(MAKE) ssh_generate_insecure_key

ssh_generate_insecure_key:
	ssh-keygen -t rsa -f $(insecure-ssh-key) -q -N ""
	chown $(shell logname): $(insecure-ssh-key)*
	$(info Copy $(insecure-ssh-key)* to ~/.ssh )
	$(info Use "ssh -i ~/.ssh/$(insecure-ssh-key) bitergia@Container_IP" when trying to log into the container via ssh)

.PHONY: clean clean_centos clean_ubuntu
clean: clean_centos clean_ubuntu

clean_centos:
	@$(MAKE) -C centos clean

clean_ubuntu:
	@$(MAKE) -C ubuntu clean

clean_ssh_keys:
	rm -f $(insecure-ssh-key)
	rm -f $(public-insecure-ssh-key)
