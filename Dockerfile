# RHEL-7 image
#
# This is based on Brian Lane's CentOS-7 Dockerfile for Composer:
# https://github.com/weldr/docker-centos7-composer
FROM registry.access.redhat.com/rhel7/rhel
MAINTAINER David Cantrell <dcantrell@redhat.com>

# systemd enabled container (from https://hub.docker.com/_/centos/)
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

# Disable subscription-manager for the purposes of this example
RUN sed -i -e 's|enabled=1|enabled=0|g' /etc/yum/pluginconf.d/subscription-manager.conf

# Copy in repo files to point to devel builds
COPY devel.repo.in /etc/yum.repos.d/devel.repo
RUN ( . /etc/os-release ; sed -i -e "s|%VER%|$VERSION_ID|g" /etc/yum.repos.d/devel.repo )

# lorax-composer depends on a couple of EPEL packages, so install the EPEL repo
RUN rpm -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# Install Cockpit, lorax-composer, and welder-web
RUN yum -y install yum-plugin-copr && \
yum -y copr enable @weldr/lorax-composer && \
yum -y install cockpit less lorax lorax-composer && \
yum clean all && \
systemctl enable cockpit.socket && \
systemctl enable lorax-composer && \
echo "root:ChangeThisLamePassword" | chpasswd

# welder-web is not setup to build from COPR yet, install it directly
RUN rpm -i https://bcl.fedorapeople.org/welder-web/welder-web-0-0.noarch.rpm

# Include some example recipes
COPY *toml /var/lib/lorax-composer/recipes/

EXPOSE 9090
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]


# Run this image with cgroups mounted:
# docker run -ti -v /sys/fs/cgroup:/sys/fs/cgroup:ro --security-opt="label:disable" -p 9090 --rm weldr/centos7-composer
