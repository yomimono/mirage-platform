#!/bin/bash -ex
# This Travis script is a bit convoluted as it can also build a chroot
# (in this instance, for an ARMel cross-arch chroot, and reexecute this
# script from within that chroot.  The chroot discards environment
# variables from the host, so we just dump them out into a shell script
# that's sourced from within the chroot too.
# This can all be cleaned up on-demand, but it does execute successfully
# from within Travis.

function setup_arm_chroot {
  echo Setting up qemu chroot for ARM
  sudo apt-get install -qq debootstrap qemu-user-static binfmt-support sbuild
  df -h
  DIR=/arm-chroot
  MIRROR=http://ftp.us.debian.org/debian/
  sudo mkdir $DIR
  sudo debootstrap --variant=buildd --include=fakeroot,build-essential --arch=armel --foreign wheezy $DIR $MIRROR
  sudo cp /usr/bin/qemu-arm-static $DIR/usr/bin/
  sudo chroot $DIR ./debootstrap/debootstrap --second-stage
  sudo sbuild-createchroot --arch=armel --foreign --setup-only wheezy $DIR $MIRROR
  echo export OCAML_VERSION=$OCAML_VERSION > envvars.sh
  echo export OPAM_VERSION=$OPAM_VERSION >> envvars.sh
  echo export XARCH=$XARCH >> envvars.sh
  echo export LANG=c >> envvars.sh
  echo export OPAMYES=1 >> envvars.sh
  echo export TRAVIS_BUILD_DIR=$TRAVIS_BUILD_DIR >> envvars.sh
  chmod a+x envvars.sh
  export LANG=c
  sudo chroot $DIR apt-get --allow-unauthenticated install -y debian-archive-keyring build-essential m4 git curl sudo
  # Add GPG key for anil@recoil.org which the ARM OPAM repo is signed with
  sudo chroot $DIR apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5896E99F
  echo 'deb [arch=armel] http://www.recoil.org/~avsm/debian-arm wheezy main' > /tmp/opamapt
  sudo mv /tmp/opamapt $DIR/etc/apt/sources.list.d/opam.list
  sudo chroot $DIR apt-get update
  sudo mkdir -p $DIR/$TRAVIS_BUILD_DIR
  sudo rsync -av $TRAVIS_BUILD_DIR/ $DIR/$TRAVIS_BUILD_DIR/
  sudo touch $DIR/.chroot_is_done
  sudo chroot $DIR bash -c "cd $TRAVIS_BUILD_DIR && ./.travis-ci.sh"
  sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam
  opam init https://github.com/ocaml/opam-repository.git
}

if [ -e "/.chroot_is_done" ]; then
  # we are in the arm chroot
  # get environment variable for inside chroot
  . ./envvars.sh
else
  if [ "$XARCH" = "arm" ]; then
    setup_arm_chroot
  else
    wget https://raw.githubusercontent.com/ocaml/ocaml-travisci-skeleton/master/.travis-ocaml.sh
    bash -ex .travis-ocaml.sh
  fi
fi

export OPAMYES=1
export OPAMVERBOSE=1
#export CI_CFLAGS=-Werror

eval `opam config env`

opam pin add -n mirage-xen-posix .
opam pin add -n mirage-xen-ocaml .

opam install mirage-unix
opam remove -a mirage-unix

opam install mirage-xen-posix mirage-xen-ocaml mirage-xen
opam remove -a mirage-xen-posix mirage-xen-ocaml mirage-xen
