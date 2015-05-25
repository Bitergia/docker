# date timestamp
imgdate = $(shell date +%Y%m%d)

# set default arch to 64-bit
default_arch = amd64
ifeq ($(findstring x86_64,$(shell arch)),)
	override arch = i386
else
	override arch = ${default_arch}
endif

ROOTFS = centos-6-rootfs

whoami = $(shell whoami)
chroot_cmd = chroot ./$(ROOTFS)
bash_chroot_cmd = $(chroot_cmd) bash -c

extra-utilities = tree less nano curl tar gzip unzip ncurses-base which
rootfs-fixes = \
	update-packages \
	add-epel-repository \
	install-extra-utils \
	fix-locales \
	disable-ttys \
	remove-ldconfig-cache \
	disable-udev \
	disable-selinux \
	fix-root-home \
	enable-networking \
	install-ssh-server \
	add-non-root-user \
	install-insecure-ssh-key \
	install-sudo \
	fix-shutdown \
	remove-unneeded-files

username = bitergia
groupname = bitergia
gen_password = $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9!@$$%^&*()_+?><~;' | fold -w 32 | head -n 1 )
insecure-ssh-key = bitergia-docker.pub

all: build
.PHONY: all

build: $(ROOTFS).tar
	docker build -t bitergia/centos-6 .
	-docker tag bitergia/centos-6 bitergia/centos-6:latest
	-docker tag bitergia/centos-6 bitergia/centos-6:${arch}
	-docker tag bitergia/centos-6 bitergia/centos-6:${imgdate}

$(ROOTFS).tar: $(ROOTFS) $(rootfs-fixes)
	cd $(ROOTFS) && tar cf ../$(ROOTFS).tar ./
	@rm -fr ./$(ROOTFS)

$(ROOTFS): check-whoami
	mkdir -p $(ROOTFS)
	rinse --arch ${arch} --verbose --distribution centos-6 --directory ./$(ROOTFS)

add-epel-repository:
	# install epel repository (available from enabled extras repository)
	@$(chroot_cmd) yum -y install epel-release

install-extra-utils:
	# install some extra utilities
	@$(chroot_cmd) yum -y install ${extra-utilities}

update-packages:
	# update the packages
	@$(chroot_cmd) yum -y update
	@$(chroot_cmd) yum -y upgrade
	@$(chroot_cmd) yum -q history sync

fix-locales:
	# remove unneeded locales and set default to en_US.UTF-8
	@$(bash_chroot_cmd) 'find /usr/share/locale -maxdepth 1 -mindepth 1 -type d | grep -v -e "en_US" | xargs rm -rfv'
	@$(bash_chroot_cmd) 'localedef --list-archive | grep -v -e "en_US" | xargs localedef --delete-from-archive'
	@$(chroot_cmd) mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
	@$(chroot_cmd) build-locale-archive
	@$(bash_chroot_cmd) "echo -e 'LANG=\"en_US.UTF-8\"\nLC_ALL=\"en_US.UTF-8\"' > /etc/sysconfig/i18n"

disable-ttys:
	# disable ttys (not needed inside the container)
	@$(chroot_cmd) sed -e 's/^\(.*:respawn:\/sbin\/getty 38400 tty.$$\)/#\1/g' -i /etc/inittab
	@$(chroot_cmd) mv /etc/init/start-ttys.conf /etc/init/start-ttys.disabled
	@$(chroot_cmd) mv /etc/init/tty.conf /etc/init/tty.disabled
	@$(chroot_cmd) mv /etc/init/serial.conf /etc/init/serial.disabled

remove-unneeded-files:
	# remove some more unneeded files
	@$(bash_chroot_cmd) 'rm -rf /usr/share/doc/*'
	@$(chroot_cmd) yum clean all

remove-ldconfig-cache:
	# remove ldconfig cache
	@$(bash_chroot_cmd) 'rm -rf /etc/ld.so.cache'
	@$(bash_chroot_cmd) 'rm -rf /var/cache/ldconfig/*'

disable-udev:
	# disable udev inside the container
	@$(chroot_cmd) sed -e 's|/sbin/start_udev||g' -i /etc/rc.d/rc.sysinit
	@$(chroot_cmd) chkconfig udev-post off

disable-selinux:
	# disable selinux
	@$(chroot_cmd) mkdir -p /selinux
	@$(bash_chroot_cmd) "echo 0 > /selinux/enforce"
	# Also kill it in the /etc/selinux/config file if it's there...
	@$(bash_chroot_cmd) "if [ -f /etc/selinux/config ]; then sed '/^SELINUX=/s/.*/SELINUX=disabled/'-i /etc/selinux/config ; fi"
	# Nice catch from Dwight Engen in the Oracle template.
	# Wantonly plagerized here with much appreciation.
	@$(bash_chroot_cmd) "if [ -f /usr/sbin/selinuxenabled ]; then mv /usr/sbin/selinuxenabled /usr/sbin/selinuxenabled.orig ; ln -s /bin/false /usr/sbin/selinuxenabled; fi"

fix-root-home:
	# add bashrc to /root
	@$(chroot_cmd) cp /etc/skel/.bash_profile /root/
	@$(chroot_cmd) cp /etc/skel/.bash_logout /root/
	@$(chroot_cmd) cp /etc/skel/.bashrc /root/

enable-networking:
	# enable networking
	@$(bash_chroot_cmd) "echo 'NETWORKING=yes' > /etc/sysconfig/network"

install-ssh-server:
	# install ssh server
	@$(chroot_cmd) yum -y install openssh-server openssh-clients
	@$(chroot_cmd) chkconfig sshd on
	@$(bash_chroot_cmd) "echo \"UseDNS no\" >> /etc/ssh/sshd_config"
	@$(bash_chroot_cmd) "echo \"GSSAPIAuthentication no\" >> /etc/ssh/sshd_config"
	@$(chroot_cmd) sed -e 's|GSSAPIAuthentication yes||g' -i /etc/ssh/sshd_config
	@$(chroot_cmd) sed -e 's|^UsePAM yes|#UsePAM yes|g' -i /etc/ssh/sshd_config
	@$(chroot_cmd) sed -e 's|^#UsePAM no|UsePAM no|g' -i /etc/ssh/sshd_config
	# start ssh daemon once to generate server keys
	@$(chroot_cmd) service sshd start
	@$(chroot_cmd) service sshd stop

add-non-root-user:
	@$(chroot_cmd) groupadd --gid 1000 $(groupname)
	@$(chroot_cmd) useradd --uid 1000 --gid 1000 --create-home --home-dir /home/$(username) $(username)
	@$(bash_chroot_cmd) "echo -n \"$(gen_password)\" | passwd --stdin ${username}"

install-insecure-ssh-key: $(insecure-ssh-key) add-non-root-user
	cp $(insecure-ssh-key) $(ROOTFS)/tmp/
	@$(chroot_cmd) mkdir -p /home/$(username)/.ssh
	@$(chroot_cmd) chmod 0700 /home/$(username)/.ssh
	@$(bash_chroot_cmd) "cat /tmp/$(insecure-ssh-key) >> /home/$(username)/.ssh/authorized_keys"
	@$(chroot_cmd) chmod 0600 /home/$(username)/.ssh/authorized_keys
	@$(chroot_cmd) chown -R $(username):$(groupname) /home/$(username)/.ssh
	@$(chroot_cmd) rm -f /tmp/$(insecure-ssh-key)

install-sudo: add-non-root-user
	@$(chroot_cmd) yum -y install sudo
	@$(chroot_cmd) sed -e 's|^# %wheel	ALL=(ALL)	NOPASSWD: ALL|%wheel	ALL=(ALL)	NOPASSWD: ALL|' -i /etc/sudoers
	@$(chroot_cmd) usermod --append --groups wheel $(username)
	@$(chroot_cmd) sed -e 's|^Default.*requiretty|#&|' -i /etc/sudoers

fix-shutdown:
	cp shutdown.conf $(ROOTFS)/etc/init/shutdown.conf

.PHONY: check-whoami
check-whoami:
ifeq ($(findstring root, ${whoami}),)
	$(warning Some commands need root permissions.)
	$(error Please use sudo to run make command.) 
else
	$(info I am root!)
endif

.PHONY: test
test: 
	@echo $(imgdate)
	@echo arch=${arch}

.PHONY: clean
clean:
	@rm -f $(ROOTFS).tar
	@rm -fr ./$(ROOTFS)

