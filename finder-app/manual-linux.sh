#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	#OUTDIR=$(realpath $1)
	OUTDIR=$1 # example: /home/meichen/Outdir
    OUTDIR=$(readlink -f "${OUTDIR}") # replace OUTDIR by its fullpath - merflix
	echo "Using passed directory ${OUTDIR} for output"
fi



mkdir -p ${OUTDIR}

if [ -d ${OUTDIR} ]; then
  echo "OUTDIR created successful ";
else 
  echo "error in directory creation ";
  exit 1 ;
fi 

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here (p.62 of my week2.odt)
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE -j$(nproc)

fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir -p $OUTDIR/rootfs
cd $OUTDIR/rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin
mkdir -p var/log


cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean # cf p1 merflix 
    make defconfig # cf p1 merflix
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE CONFIG_PREFIX=$OUTDIR/rootfs install -j$(nproc)

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp  $SYSROOT/lib/ld-linux-aarch64.so.1 $OUTDIR/rootfs/lib
cp  $SYSROOT/lib64/libm.so.6 $OUTDIR/rootfs/lib64
cp  $SYSROOT/lib64/libresolv.so.2 $OUTDIR/rootfs/lib64
cp  $SYSROOT/lib64/libc.so.6 $OUTDIR/rootfs/lib64

# TODO: Make device nodes
cd $OUTDIR/rootfs

sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1

cd "$OUTDIR"

# TODO: Clean and build the writer utility
if [ -f writer ]; then
    rm -rf *.o
	rm writer
fi

${CROSS_COMPILE}gcc -o writer.o -c $FINDER_APP_DIR/writer.c -W -Wall
${CROSS_COMPILE}gcc -o writer writer.o

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp writer $OUTDIR/rootfs/home
cp $FINDER_APP_DIR/finder-test.sh $OUTDIR/rootfs/home
cp $FINDER_APP_DIR/finder.sh $OUTDIR/rootfs/home
cp $FINDER_APP_DIR/autorun-qemu.sh $OUTDIR/rootfs/home

mkdir -p $OUTDIR/rootfs/home/conf
mkdir -p $OUTDIR/rootfs/conf
cp $FINDER_APP_DIR/conf/username.txt $OUTDIR/rootfs/home/conf
cp $FINDER_APP_DIR/conf/assignment.txt $OUTDIR/rootfs/home/conf
cp $FINDER_APP_DIR/conf/assignment.txt $OUTDIR/rootfs/conf


# TODO: Chown the root directory
cd $OUTDIR/rootfs
sudo chown -R root:root *
cd "$OUTDIR"

# TODO: Create initramfs.cpio.gz
#if [ -f initramfs.cpio.gz ]; then
#    rm initramfs.cpio.gz
#fi

cd $OUTDIR/rootfs
find . | cpio -H newc -ov --owner root:root > ../initramfs.cpio
cd ..
gzip initramfs.cpio
cd "$OUTDIR" # make sure to be back in OUTDIR

mkimage -A arm64 -O linux -T ramdisk -C gzip -d initramfs.cpio.gz initramfs


