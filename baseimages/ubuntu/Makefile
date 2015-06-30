# date timestamp
imgdate = $(shell date +%Y%m%d)

# set default arch to 64-bit
default_arch = amd64
ifeq ($(findstring x86_64,$(shell arch)),)
	override arch = i386
else
	override arch = ${default_arch}
endif

dist = ubuntu
suite= trusty
dist-name = $(dist)-$(suite)
mirror = http://archive.ubuntu.com/ubuntu
ROOTFS = $(dist-name)-rootfs

whoami = $(shell whoami)
chroot_cmd = chroot ./$(ROOTFS)
bash_chroot_cmd = $(chroot_cmd) bash -c
apt-env = DEBIAN_FRONTEND=noninteractive INITRD=no
apt-get-install = $(apt-env) apt-get -y install --no-install-recommends

includes = apt-utils,ubuntu-minimal
extra-utilities = tree less nano curl tar gzip unzip ncurses-base ca-certificates
rootfs-fixes = \
	fix-sources-list \
	fix-locales \
	disable-apt-recommends \
	enable-apt-index-compression \
	disable-unwanted-files \
	fix-initctl \
	update-packages \
	install-extra-utils \
	disable-ttys \
	disable-unneeded-services \
	restore-initctl \
	install-ssh-server \
	add-non-root-user \
	install-insecure-ssh-key \
	install-sudo \
	remove-unneeded-files \
	fix-init

username = bitergia
groupname = bitergia
gen_password = $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9!@$$%^&*()_+?><~;' | fold -w 32 | head -n 1 )
insecure-ssh-key = bitergia-docker.pub

upstart_tty = tty1 tty2 tty3 tty4 tty5 tty6 tty7 tty8 tty9
upstart_services = checkfs.sh checkroot-bootclean.sh checkroot.sh control-alt-delete hostname hwclock hwclock-save mountall-bootclean.sh mountall mountall-net mountall-reboot mountall.sh mountall-shell mountdevsubfs.sh mounted-debugfs mounted-dev mounted-proc mounted-run mounted-tmp mounted-var mountkernfs.sh mountnfs-bootclean.sh mountnfs.sh networking plymouth plymouth-log plymouth-ready plymouth-shutdown plymouth-splash plymouth-stop plymouth-upstart-bridge resolvconf udev udev-fallback-graphics udev-finish udevmonitor udevtrigger
initd_services = umountfs umountroot hwclock.sh hwclockfirst.sh module-init-tools udev resolvconf ondemand rsyslog

all: build
.PHONY: all

build: $(ROOTFS).tar
	docker build -t bitergia/$(dist-name) .
	-docker tag -f bitergia/$(dist-name) bitergia/$(dist-name):latest
	-docker tag bitergia/$(dist-name) bitergia/$(dist-name):${arch}
	-docker tag bitergia/$(dist-name) bitergia/$(dist-name):${imgdate}

$(ROOTFS).tar: $(ROOTFS) $(rootfs-fixes)
	cd $(ROOTFS) && tar cf ../$(ROOTFS).tar ./
	@rm -fr ./$(ROOTFS)

$(ROOTFS): check-whoami
	mkdir -p $(ROOTFS)
	debootstrap --arch ${arch} --verbose --variant=minbase --components=main,universe --include="$(includes)" $(suite) ./$(ROOTFS) $(mirror)

install-extra-utils:
	# install some extra utilities
	@$(bash_chroot_cmd) "$(apt-get-install) ${extra-utilities}"

fix-sources-list:
	@$(bash_chroot_cmd) "echo \"deb http://archive.ubuntu.com/ubuntu $(suite)-updates main universe\" >> /etc/apt/sources.list"
	@$(bash_chroot_cmd) "echo \"deb http://archive.ubuntu.com/ubuntu $(suite)-security main universe\" >> /etc/apt/sources.list"

update-packages:
	# update the packages
	@$(chroot_cmd) apt-get -y update
	@$(bash_chroot_cmd) "$(apt-env) apt-get -y dist-upgrade --no-install-recommends"

fix-initctl:
	## Fix some issues with APT packages.
	## See https://github.com/dotcloud/docker/issues/1024
	@$(chroot_cmd) dpkg-divert --local --rename --add /sbin/initctl
	@$(chroot_cmd) ln -sf /bin/true /sbin/initctl
	@$(bash_chroot_cmd) "echo -e \"#!/bin/sh\nexit 101\n\" > /usr/sbin/policy-rc.d"
	@$(chroot_cmd) chmod +x /usr/sbin/policy-rc.d

restore-initctl:
	@$(chroot_cmd) rm -f /usr/sbin/policy-rc.d
	@$(chroot_cmd) rm -f /sbin/initctl
	@$(chroot_cmd) dpkg-divert --local --rename --remove /sbin/initctl

fix-locales:
	# remove unneeded locales and set default to en_US.UTF-8
	@$(bash_chroot_cmd) "echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen"
	@$(chroot_cmd) locale-gen en_US.UTF-8
	@$(chroot_cmd) update-locale LANG=en_US.UTF-8
	@$(bash_chroot_cmd) 'find /usr/share/locale -maxdepth 1 -mindepth 1 -type d | grep -v -e "en_US" | xargs rm -rfv'
	@$(bash_chroot_cmd) 'localedef --list-archive | grep -v -e "en_US" | xargs localedef --delete-from-archive'

disable-apt-recommends:
	# disable apt recommends
	@$(bash_chroot_cmd) "echo 'APT::Install-Recommends \"0\";' >> /etc/apt/apt.conf.d/90recommends"
	@$(bash_chroot_cmd) "echo 'Aptitude::Recommends-Important \"false\";' >> /etc/apt/apt.conf.d/90recommends"

enable-apt-index-compression:
	@$(bash_chroot_cmd) "echo 'Acquire::GzipIndexes \"true\";' >> /etc/apt/apt.conf.d/10compress-indexes"
	@$(bash_chroot_cmd) "echo 'Acquire::CompressionTypes::Order:: \"gz\";' >> /etc/apt/apt.conf.d/10compress-indexes"

disable-unwanted-files:
	# avoid unwanted locales and other files
	@$(bash_chroot_cmd) "echo '# Drop locales except en US' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude=/usr/share/locale/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-include=/usr/share/locale/en*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-include=/usr/share/locale/locale.alias' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo '# Drop documentation' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude=/usr/share/man/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude=/usr/share/doc/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude=/usr/share/info/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude /usr/share/groff/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo '# keep copyright files for legal reasons' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-include /usr/share/doc/*/copyright$$' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo '# lintian stuff is small, but really unnecessary' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude /usr/share/lintian/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"
	@$(bash_chroot_cmd) "echo 'path-exclude /usr/share/linda/*' >> /etc/dpkg/dpkg.cfg.d/01_excludes"

disable-ttys:
	# disable ttys (not needed inside the container)
	@$(bash_chroot_cmd) "if [ -e /etc/inittab ]; then sed -e 's/^\(.*:respawn:\/sbin\/getty 38400 tty.$$\)/#\1/g' -i /etc/inittab ; fi"
	@$(bash_chroot_cmd) "for f in $(upstart_tty); do if [ -e /etc/init/\$$f.conf ]; then mv -f /etc/init/\$$f.conf /etc/init/\$$f.disabled ; fi ; done"

disable-unneeded-services:
	@$(bash_chroot_cmd) "for f in $(initd_services); do /usr/sbin/update-rc.d -f \$$f remove ; done"
	@$(bash_chroot_cmd) "for f in $(upstart_services); do if [ -e /etc/init/\$$f.conf ]; then mv -f /etc/init/\$$f.conf /etc/init/\$$f.disabled ; fi ; done"

remove-unneeded-files:
	# remove some more unneeded files
	@$(chroot_cmd) apt-get clean
	@$(chroot_cmd) rm -rf /usr/share/doc/*
	@$(chroot_cmd) find /var/lib/apt/lists -type f -delete
	@$(chroot_cmd) rm -rf /tmp/* /var/tmp/*

install-ssh-server:
	# install ssh server
	@$(bash_chroot_cmd) "$(apt-get-install) openssh-server openssh-sftp-server openssh-client"
	@$(bash_chroot_cmd) "echo \"UseDNS no\" >> /etc/ssh/sshd_config"
	@$(bash_chroot_cmd) "echo \"GSSAPIAuthentication no\" >> /etc/ssh/sshd_config"
	@$(chroot_cmd) sed -e 's|GSSAPIAuthentication yes||g' -i /etc/ssh/sshd_config
	@$(chroot_cmd) sed -e 's|^UsePAM yes|#UsePAM yes|g' -i /etc/ssh/sshd_config
	@$(chroot_cmd) sed -e 's|^#UsePAM no|UsePAM no|g' -i /etc/ssh/sshd_config

add-non-root-user:
	@$(chroot_cmd) addgroup --gid 1000 $(groupname)
	@$(chroot_cmd) adduser --uid 1000 --gid 1000 --home /home/$(username) --gecos $(username) --disabled-password $(username)
	@$(bash_chroot_cmd) "echo -n \"$(username):$(gen_password)\" | chpasswd"

install-insecure-ssh-key: $(insecure-ssh-key) add-non-root-user
	cp $(insecure-ssh-key) $(ROOTFS)/tmp/
	@$(chroot_cmd) mkdir -p /home/$(username)/.ssh
	@$(chroot_cmd) chmod 0700 /home/$(username)/.ssh
	@$(bash_chroot_cmd) "cat /tmp/$(insecure-ssh-key) >> /home/$(username)/.ssh/authorized_keys"
	@$(chroot_cmd) chmod 0600 /home/$(username)/.ssh/authorized_keys
	@$(chroot_cmd) chown -R $(username):$(groupname) /home/$(username)/.ssh
	@$(chroot_cmd) rm -f /tmp/$(insecure-ssh-key)

install-sudo: add-non-root-user
	@$(bash_chroot_cmd) "$(apt-get-install) sudo"
	@$(chroot_cmd) adduser $(username) sudo
	@$(chroot_cmd) sed -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' -i /etc/sudoers

fix-init:
	cp init-fake.conf $(ROOTFS)/etc/init/fake-container-events.conf
	@$(bash_chroot_cmd) "echo '# /lib/init/fstab: cleared out for bare-bones Docker' > /lib/init/fstab"

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

