#!/bin/bash
set -euxo pipefail

readonly ROS_DISTRO=$1
readonly ROS_APT_HTTP_REPO_URLS=$2

apt-get update
apt-get install --no-install-recommends --quiet --yes sudo

# NOTE: this user is added for backward compatibility.
# Before the resolution of ros-tooling/setup-ros-docker#7 we used `USER rosbuild:rosbuild`
# and recommended that users of these containers run the following step in their workflow
# - run: sudo chown -R rosbuild:rosbuild "$HOME" .
# For repositories that still have this command in their workflow, they would fail if the user
# did not still exist. This user is no longer used but is just present so that command succeeds.
groupadd -r rosbuild
useradd --no-log-init --create-home -r -g rosbuild rosbuild
echo "rosbuild ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo 'Etc/UTC' > /etc/timezone

apt-get update

apt-get install --no-install-recommends --quiet --yes \
    curl gnupg2 locales lsb-release

locale-gen en_US en_US.UTF-8
export LANG=en_US.UTF-8

ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

apt-get install --no-install-recommends --quiet --yes tzdata

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

for URL in ${ROS_APT_HTTP_REPO_URLS//,/ }; do
    echo "deb ${URL}/ubuntu $(lsb_release -sc) main" >> /etc/apt/sources.list.d/ros-latest.list
done

case ${ROS_DISTRO} in
    "kinetic" | "melodic")
        ROSDEP_APT_PACKAGE="python-rosdep"
        ;;
    *)
        ROSDEP_APT_PACKAGE="python3-rosdep"
        ;;
esac

apt-get update

DEBIAN_FRONTEND=noninteractive \
RTI_NC_LICENSE_ACCEPTED=yes \
apt-get install --no-install-recommends --quiet --yes \
	build-essential \
	clang \
	cmake \
	git \
	lcov \
	libasio-dev \
	libc++-dev \
	libc++abi-dev \
	libssl-dev \
	libtinyxml2-dev \
	python3-dev \
	python3-pip \
	python3-vcstool \
	python3-wheel \
	${ROSDEP_APT_PACKAGE} \
	rti-connext-dds-5.3.1 \
	wget

# libopensplice69 does not exist on Ubuntu 20.04, so we're attempting to
# install it, but won't fail if it does not suceed.
apt-get install --no-install-recommends --quiet --yes libopensplice69 || true

# Get the latest version of pip before installing dependencies,
# the version from apt can be very out of date (v8.0 on xenial)
# The latest version of pip doesn't support Python3.5 as of v21,
# but pip 8 doesn't understand the metadata that states this, so we must first
# make an intermediate upgrade to pip 20, which does understand that information
python3 -m pip install --upgrade pip==20.*
python3 -m pip install --upgrade pip

pip3 install --upgrade -r requirements.txt

rosdep init

rm -rf "/var/lib/apt/lists/*"
