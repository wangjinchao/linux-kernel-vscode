# This file is sourced in the middle of tasks.sh, after environment variables
# are setup and before commands are run. It does not get updated by the update
# task so you can use it to plug-in arbitrary extra logic that is specific to
# your local needs and should not be part of the upstream tasks.sh. For example:

## Cross-compile/debug/emulate for arm64
# TARGET_ARCH=arm64

## Change PATH to use a different QEMU binary
# export PATH=$HOME/qemu/bin/:$PATH

## Generate objects in a subdirectory
# MAKE="$MAKE O=.vscode/build-$TARGET_ARCH/"
MAKE="date;time make -j`nproc` LLVM=1 LLVM_IAS=1 CC='ccache clang'"
# MAKE="date;time make -j`nproc` CC='ccache gcc'"

## Enable some random kernel CONFIG by default as part of the .config generation
# if [ $COMMAND = "defconfig" ]; then
#   trap "scripts/config -e BPF_SYSCALL" EXIT
# fi

## Run make olddefconfig before a build (a bit slow)
# if [ $COMMAND = "build" ]; then
#   eval ${MAKE} ARCH=${TARGET_ARCH} olddefconfig
# fi

## Make the build verbose
SILENT_BUILD_FLAG=""

## Disable the build spinner
# SPINNER=0

## Don't clear the screen before each task
# unset CLEAR

## Boot without systemd (use the /sbin/init-minimal shell script instead)
# SKIP_SYSTEMD=1

## Add some args to the kernel cmdline when using the "start" task
## E.g.: Boot straight into a syzbot reproducer
# KERNEL_CMDLINE_EXTRA=init=/root/syzbot-repro
KERNEL_CMDLINE_EXTRA="audit=0"

## Only fuzz the /dev/ptmx ioctls
# SYZ_MANAGER_CFG_EXTRA='"enable_syscalls": [ "openat$ptmx", "ioctl$*" ],'

## Fuzz as an unprivileged user
# SYZ_MANAGER_CFG_EXTRA='"sandbox": "setuid",'

# Create 4 SATA disk images (10GB each) if they don't exist
DISK_DIR="/home/jinchao/.linux-kernel-vscode"
for i in {1..4}; do
  if [ ! -f "${DISK_DIR}/sata_disk${i}.img" ]; then
    qemu-img create -f qcow2 "${DISK_DIR}/sata_disk${i}.img" 10G
  fi
done

# Create 2 NVMe disk images (4GB each) if they don't exist
for i in {1..2}; do
  if [ ! -f "${DISK_DIR}/nvme_disk${i}.img" ]; then
    qemu-img create -f qcow2 "${DISK_DIR}/nvme_disk${i}.img" 4G
  fi
done

# Configure VM_START_ARGS to include the additional disks
VM_START_ARGS="-drive file=${DISK_DIR}/sata_disk1.img,if=ide \
-drive file=${DISK_DIR}/sata_disk2.img,if=ide \
-drive file=${DISK_DIR}/sata_disk3.img,if=ide \
-drive file=${DISK_DIR}/sata_disk4.img,if=ide \
-drive file=${DISK_DIR}/nvme_disk1.img,if=none,id=nvme1 \
-device nvme,drive=nvme1,serial=nvme1 \
-drive file=${DISK_DIR}/nvme_disk2.img,if=none,id=nvme2 \
-device nvme,drive=nvme2,serial=nvme2"