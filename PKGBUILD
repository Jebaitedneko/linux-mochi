# Maintainer: Jan Alexander Steffens (heftig) <heftig@archlinux.org>
# Maintainer: Jebaitedneko <jebaitedneko@gmail.com>

##
## The following variables can be customized at build time. Use env or export to change at your wish
##
##   Example: env _microarchitecture=99 use_numa=n use_tracers=n use_pds=n makepkg -sc
##
## Look inside 'misc/choose-gcc-optimization.sh' to choose your microarchitecture
## Valid numbers between: 0 to 99
## Default is: 0 => generic
## Good option if your package is for one machine: 99 => native
if [ -z ${_microarchitecture+x} ]; then
  _microarchitecture=0
fi

## Disable NUMA since most users do not have multiple processors. Breaks CUDA/NvEnc.
## Archlinux and Xanmod enable it by default.
## Set variable "use_numa" to: n to disable (possibly increase performance)
##                             y to enable  (stock default)
if [ -z ${use_numa+x} ]; then
  use_numa=n
fi

## For performance you can disable FUNCTION_TRACER/GRAPH_TRACER. Limits debugging and analyzing of the kernel.
## Stock Archlinux and Xanmod have this enabled. 
## Set variable "use_tracers" to: n to disable (possibly increase performance)
##                                y to enable  (stock default)
if [ -z ${use_tracers+x} ]; then
  use_tracers=n
fi

## Enable CONFIG_USER_NS_UNPRIVILEGED flag https://aur.archlinux.org/cgit/aur.git/tree/0001-ZEN-Add-sysctl-and-CONFIG-to-disallow-unprivileged-C.patch?h=linux-ck
## Set variable "use_ns" to: n to disable (stock Xanmod)
##                           y to enable (stock Archlinux)
if [ -z ${use_ns+x} ]; then
  use_ns=y
fi

# Compile ONLY used modules to VASTLYreduce the number of modules built
# and the build time.
#
# To keep track of which modules are needed for your specific system/hardware,
# give module_db script a try: https://aur.archlinux.org/packages/modprobed-db
# This PKGBUILD read the database kept if it exists
#
# More at this wiki page ---> https://wiki.archlinux.org/index.php/Modprobed-db
if [ -z ${_localmodcfg} ]; then
  _localmodcfg=n
fi

# Check if you're building on CI, default N.
if [ -z ${cibuild+x} ]; then
  cibuild=n
fi

# Check if lld needs to be selected, default N.
if [ -z ${lld+x} ]; then
  lld=n
fi

# Allow a vanilla archlinux kernel build, default N.
if [ -z ${arch_source+x} ]; then
  arch_source=n
fi

# Tweak kernel options prior to a build via nconfig
_makenconfig=

### IMPORTANT: Do no edit below this line unless you know what you're doing

# Change package name according to arch.
local active_arch=$(
  if [[ $_microarchitecture != 0 ]]; then
    cat misc/choose-gcc-optimization.sh |\
    grep "${_microarchitecture})" |\
    grep -Eo "CONFIG.*" |\
    cut -f1 -d ' ' |\
    sed "s/CONFIG_M//g" |\
    head -1
  else
    if [[ $_microarchitecture == 99 ]]; then
      echo "NATIVE"
    fi
    echo "GENERIC"
  fi
)

# Check for custom pkgbase name, default is the extracted pkgbase.
if [ -z ${custpkgbase+x} ]; then
  pkgbase=linux-mochi-${active_arch,,}
fi

# If custom name is present, use it.
if [ "$custpkgbase" != "" ]; then
  pkgbase=linux-$custpkgbase
fi

_major=5.12
_branch=5.x

pkgver=${_major}.14.zen1
pkgname=("${pkgbase}" "${pkgbase}-headers")
pkgrel=1
pkgdesc='Linux ZEN'

_srctag=v${pkgver%.*}-${pkgver##*.}
url="https://github.com/zen-kernel/zen-kernel/commits/$_srctag"
arch=(x86_64)
_zen_sha="e036abbdf0cf4e914fd0acecf93c026a6bf6bc1c" # 5.12.14.zen1-1
_arch_sha="ec9e9a4219fe221dec93fa16fddbe44a34933d8d" # 5.12.14.arch1-1

license=(GPL2)

makedepends=(
  xmlto kmod inetutils bc libelf cpio
  python-sphinx python-sphinx_rtd_theme graphviz imagemagick git
)

options=('!strip')

_srcname="linux-${pkgver}"

source=(
    "https://cdn.kernel.org/pub/linux/kernel/v${_branch}/linux-${_major}.tar."{xz,sign}
    "https://github.com/zen-kernel/zen-kernel/releases/download/v${pkgver/.zen/-zen}/v${pkgver/.zen/-zen}.patch.xz"
)

sha256sums=(
    "SKIP"
    "SKIP"
    "SKIP"
)

validpgpkeys=(
    'ABAF11C65A2970B130ABE3C479BE3E4300411886'  # Linus Torvalds
    '647F28654894E3BD457199BE38DBBDC86092693E'  # Greg Kroah-Hartman
    'A2FF3A36AAA56654109064AB19802F8B0D70FC30'  # Jan Alexander Steffens (heftig)
)

# Archlinux patches
_commits=""
for _patch in $_commits; do
    source+=("${_patch}.patch::https://git.archlinux.org/linux.git/patch/?id=${_patch}")
done

export KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-archlinux}
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-makepkg}
export KBUILD_BUILD_TIMESTAMP=${KBUILD_BUILD_TIMESTAMP:-$(date -Ru${SOURCE_DATE_EPOCH:+d @$SOURCE_DATE_EPOCH})}

prepare() {

  if [ "$arch_source" = "y" ]; then
    msg2 "arch_source=y detected. performing a squashed revert of a few patches..."
    (
        cd linux-${_major}/../..
	    patch -Np1 < "misc/patches/1_misc/SKIP_0000-ANNOTATION-Reverts-for-switching-to-arch-source.patch"
    )
  fi

  cd linux-${_major}

  msg2 "ZEN patch not found. Applying workaround..."
  [ ! -f ../../v${pkgver/.zen/-zen}.patch ] \
    && xz -d ../../v${pkgver/.zen/-zen}.patch.xz \
    && mv ../../v${pkgver/.zen/-zen}.patch ../

  if [ "$arch_source" = "n" ]; then
    msg2 "arch_source=y not passed. assuming zen..."
    # Apply ZEN patch
    patch -Np1 -i ../v${pkgver/.zen/-zen}.patch
  fi

  local _localversion=`echo "-$pkgbase" | sed "s/linux-//g;s/xanmod-//g;s/[a-z A-Z]/\U&/g"`
  msg2 "Setting version to ${_localversion}"
  scripts/setlocalversion --save-scmversion
  #echo "-$pkgrel" > localversion.10-pkgrel
  echo ${_localversion} > localversion.10-pkgbase

  # Archlinux patches
  local src
  for src in "${source[@]}"; do
    src="${src%%::*}"
    src="${src##*/}"
    [[ $src = *.patch ]] || continue
    msg2 "Applying patch $src..."
    patch -Np1 < "../$src"
  done

  curl -s "https://raw.githubusercontent.com/archlinux/svntogit-packages/${_zen_sha}/trunk/config" > .config
  if [ "$arch_source" = "y" ]; then
	msg2 "Applying archlinux config..."
	curl -s "https://raw.githubusercontent.com/archlinux/svntogit-packages/${_arch_sha}/trunk/config" > .config
  fi

  # Custom Patches
  # ( cd ../../ && ./misc/getpatches.sh ) # uncomment to re-enable auto-fetching
  patch_dir=../../misc/patches
  for d in $(cd $patch_dir && ls -1); do
    for i in {1000..0}; do
		patch_file="$patch_dir/${d}/${i}_*.patch"
        [ -f $patch_file ] && echo -e "\n$(ls -1 $patch_file)" &&
            msg2 "Applying patch ${i} from ${d}" && patch -Np1 < $patch_file
    done
  done
  sed -i "/HAVE_DEBUG_KMEMLEAK/d" arch/x86/Kconfig
  sed -i "/ARCH_HAS_KCOV/d" arch/x86/Kconfig
  sed -i "/ARCH_HAS_DEBUG_WX/d" arch/x86/Kconfig
  sed -i "/ARCH_HAS_DEBUG_VIRTUAL/d" arch/x86/Kconfig
  sed -i "/ARCH_HAS_DEBUG_VM_PGTABLE/d" arch/x86/Kconfig
  sed -i "/ARCH_SUPPORTS_DEBUG_PAGEALLOC/d" arch/x86/Kconfig
  sed -i "/SYSCTL_EXCEPTION_TRACE/d" arch/x86/Kconfig
  sed -i "/TASKS_TRACE_RCU/d" init/Kconfig
  sed -i "s/if EXPERT/if !EXPERT/g" arch/x86/Kconfig.debug
  sed -i "s/default !EXPERT/default EXPERT/g" lib/Kconfig.debug
  sed -i "s/if EXPERT/if !EXPERT/g" drivers/infiniband/ulp/ipoib/Kconfig
  sed -i "s/if EXPERT/if !EXPERT/g" drivers/infiniband/hw/mthca/Kconfig
  sed -i "s/def_bool BT_CMTP/def_bool n/g;s/&&/||/g" drivers/isdn/capi/Kconfig
  sed -i "s/=y/=m/g" net/ipv4/Kconfig
  # scripts/config --enable CONFIG_LD_DEAD_CODE_DATA_ELIMINATION
  # scripts/config --enable CONFIG_INLINE_OPTIMIZATION
  scripts/config --enable CONFIG_INIT_STACK_ALL_ZERO
  scripts/config --disable CONFIG_DEBUG_KERNEL
  scripts/config --disable CONFIG_DEBUG_MISC
  scripts/config --disable CONFIG_DEBUG_WX
  scripts/config --disable CONFIG_SCHED_DEBUG
  scripts/config --disable CONFIG_KALLSYMS_ALL
  scripts/config --disable CONFIG_PM_DEBUG
  scripts/config --disable CONFIG_PM_ADVANCED_DEBUG
  scripts/config --disable CONFIG_PM_SLEEP_DEBUG
  scripts/config --disable CONFIG_ACPI_DEBUG
  scripts/config --disable CONFIG_SCSI_DEBUG
  scripts/config --disable CONFIG_SCSI_LOGGING
  scripts/config --disable CONFIG_HAVE_DEBUG_KMEMLEAK
  scripts/config --disable CONFIG_HYPERVISOR_GUEST
  scripts/config --disable CONFIG_IOSF_MBI_DEBUG
  scripts/config --disable CONFIG_ACPI_DEBUGGER
  scripts/config --disable CONFIG_ACPI_DEBUGGER_USER
  scripts/config --disable ARCH_HAS_DEBUG_WX
  scripts/config --disable CONFIG_MLX4_DEBUG
  scripts/config --disable CONFIG_NFS_DEBUG
  scripts/config --disable LOCK_DEBUGGING_SUPPORT
  scripts/config --disable CONFIG_SUNRPC_DEBUG
  scripts/config --disable CONFIG_PUNIT_ATOM_DEBUG
  scripts/config --disable CONFIG_ACPI_EC_DEBUGFS
  scripts/config --disable CONFIG_RTW88_DEBUG
  scripts/config --disable CONFIG_RTW88_DEBUGFS
  scripts/config --disable CONFIG_WILCO_EC_DEBUGFS
  scripts/config --disable CONFIG_WIL6210_DEBUGFS
  scripts/config --disable CONFIG_SMS_SIANO_DEBUGFS
  scripts/config --disable CONFIG_MAC80211_DEBUGFS
  scripts/config --disable CONFIG_ATH10K_DEBUGFS
  scripts/config --disable CONFIG_ATH9K_DEBUGFS
  scripts/config --disable CONFIG_ATH9K_HTC_DEBUGFS
  scripts/config --disable CONFIG_BT_DEBUGFS
  scripts/config --disable CONFIG_CFG80211_DEBUGFS
  scripts/config --disable CONFIG_CROS_EC_DEBUGFS
  scripts/config --disable CONFIG_IEEE802154_AT86RF230_DEBUGFS
  scripts/config --disable CONFIG_IEEE802154_CA8210_DEBUGFS
  scripts/config --disable CONFIG_IWLEGACY_DEBUGFS
  scripts/config --disable CONFIG_IWLWIFI_DEBUGFS
  scripts/config --disable CONFIG_L2TP_DEBUGFS
  scripts/config --disable CONFIG_BLK_DEBUG_FS
  scripts/config --disable CONFIG_THINKPAD_ACPI_DEBUGFACILITIES
  scripts/config --disable CONFIG_DEBUG_MEMORY_INIT
  scripts/config --disable CONFIG_CIFS_DEBUG
  scripts/config --disable CONFIG_DYNAMIC_DEBUG
  scripts/config --disable CONFIG_DYNAMIC_DEBUG_CORE
  scripts/config --disable CONFIG_X86_DEBUGCTLMSR
  scripts/config --disable CONFIG_INFINIBAND_IPOIB_DEBUG
  scripts/config --disable CONFIG_INFINIBAND_MTHCA_DEBUG
  scripts/config --disable PAGE_POISONING
  scripts/config --disable CONFIG_SYSTEM_DATA_VERIFICATION
  scripts/config --disable CONFIG_MODULE_SIG
  scripts/config --disable CONFIG_MODULE_SIG_ALL
  scripts/config --disable CONFIG_TASKS_TRACE_RCU
  scripts/config --disable CONFIG_SCSI_IPR_TRACE
  scripts/config --disable CONFIG_BRCM_TRACING
  scripts/config --disable CONFIG_TRACE_ROUTER
  scripts/config --disable CONFIG_TRACE_SINK
  scripts/config --disable CONFIG_NETFILTER_XT_TARGET_TRACE
  scripts/config --disable CONFIG_CAPI_TRACE
  scripts/config --disable CONFIG_HAVE_STACK_VALIDATION
  scripts/config --disable CONFIG_SCSI_ESAS2R
  scripts/config --disable CONFIG_DEFAULT_FQ_PIE
  scripts/config --enable CONFIG_DEFAULT_FQ_CODEL
  scripts/config --disable CONFIG_TCP_CONG_BBR2
  scripts/config --disable CONFIG_DEFAULT_BBR2
  scripts/config --disable CONFIG_DEFAULT_CUBIC
  scripts/config --enable CONFIG_DEFAULT_BBR
  scripts/config --enable CONFIG_HIGH_RES_TIMERS

  msg2 "Getting hamadmarri's auto config"
  wget -q "https://github.com/hamadmarri/cacule-cpu-scheduler/raw/master/scripts/apply_suggested_configs.sh"
  msg2 "Applying auto config"
  chmod +x apply_suggested_configs.sh
  ./apply_suggested_configs.sh
#   msg2 "Getting hamadmarri's cacule sched"
#   wget -q "https://raw.githubusercontent.com/hamadmarri/cacule-cpu-scheduler/master/patches/CacULE/v${_major}/cacule-${_major}.patch"
#   msg2 "Applying cacule patch"
#   patch -Np1 < cacule-${_major}.patch
#   scripts/config --disable CONFIG_CACULE_SCHED
  # scripts/config --enable CACULE_RDB

  scripts/config --enable CONFIG_LTO
  scripts/config --enable LTO_GCC

  scripts/config --enable CONFIG_BOOTSPLASH

  # Enable IKCONFIG following Arch's philosophy
  scripts/config --enable CONFIG_IKCONFIG \
                 --enable CONFIG_IKCONFIG_PROC

  # User set. See at the top of this file
  if [ "$use_tracers" = "n" ]; then
    msg2 "Disabling FUNCTION_TRACER/GRAPH_TRACER..."
    scripts/config --disable CONFIG_FUNCTION_TRACER \
                   --disable CONFIG_STACK_TRACER
  fi

  if [ "$use_numa" = "n" ]; then
    msg2 "Disabling NUMA..."
    scripts/config --disable CONFIG_NUMA
  fi

  if [ "$use_ns" = "n" ]; then
    msg2 "Disabling CONFIG_USER_NS_UNPRIVILEGED"
    scripts/config --disable CONFIG_USER_NS_UNPRIVILEGED
  fi

  local _hostname=`echo $pkgbase | sed "s/linux-//g"`
  scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "${_hostname}"

  scripts/config --disable CONFIG_HZ_500
  scripts/config --enable CONFIG_HZ_1000

  # Let's user choose microarchitecture optimization in GCC
  sh ../../misc/choose-gcc-optimization.sh $_microarchitecture

  # This is intended for the people that want to build this package with their own config
  # Put the file "myconfig" at the package folder to use this feature
  # If it's a full config, will be replaced
  # If not, you should use scripts/config commands, one by line
  if [ -f "${startdir}/myconfig" ]; then
    if ! grep -q 'scripts/config' "${startdir}/myconfig"; then
      # myconfig is a full config file. Replacing default .config
      msg2 "Using user CUSTOM config..."
      cp -f "${startdir}"/myconfig .config
    else
      # myconfig is a partial file. Applying every line
      msg2 "Applying configs..."
      cat "${startdir}"/myconfig | while read -r _linec ; do
        if echo "$_linec" | grep "scripts/config" ; then
          set -- $_linec
          "$@"
        else
          warning "Line format incorrect, ignoring..."
        fi
      done
    fi
    echo
  fi

  make olddefconfig

  ### Optionally load needed modules for the make localmodconfig
  # See https://aur.archlinux.org/packages/modprobed-db
  if [ "$_localmodcfg" = "y" ]; then
    if [ -f $HOME/.config/modprobed.db ]; then
      msg2 "Running Steven Rostedt's make localmodconfig now"
      make LSMOD=$HOME/.config/modprobed.db localmodconfig
    else
      msg2 "No modprobed.db data found"
      exit
    fi
  fi

  make -s kernelrelease > version
  msg2 "Prepared %s version %s" "$pkgbase" "$(<version)"

  [[ -z "$_makenconfig" ]] || make nconfig

  # save configuration for later reuse
  cat .config > "${startdir}/config.last"
}

build() {
  cd linux-${_major}
  if [ "$lld" = "y" ]; then
	wget https://github.com/kdrag0n/proton-clang/raw/master/bin/lld -O ld.lld && chmod +x ld.lld
  fi
  if [ "$cibuild" = "y" ]; then
    msg2 "CI Build Starting..."
    make -j$((`nproc`+2)) \
		$([ "$lld" = "y" ] && echo "LD=$(pwd)/ld.lld HOSTLD=$(pwd)/ld.lld") \
		all
  else
    msg2 "Normal Build Starting..."
	make -j$((`nproc`+2)) \
		$([ "$lld" = "y" ] && echo "LD=$(pwd)/ld.lld HOSTLD=$(pwd)/ld.lld") \
		CC="ccache gcc" \
		all
  fi
}

_package() {
  pkgdesc="The $pkgdesc kernel and modules"
  depends=(coreutils kmod initramfs)
  optdepends=('crda: to set the correct wireless channels of your country'
              'linux-firmware: firmware images needed for some devices')
  provides=(VIRTUALBOX-GUEST-MODULES WIREGUARD-MODULE VHBA-MODULE)
  replaces=()
  conflicts=()

  cd linux-${_major}
  local kernver="$(<version)"
  local modulesdir="$pkgdir/usr/lib/modules/$kernver"

  msg2 "Installing boot image..."
  # systemd expects to find the kernel here to allow hibernation
  # https://github.com/systemd/systemd/commit/edda44605f06a41fb86b7ab8128dcf99161d2344
  install -Dm644 "$(make -s image_name)" "$modulesdir/vmlinuz"

  # Used by mkinitcpio to name the kernel
  local _cpio_name=`echo $pkgbase | sed "s/linux-//g"`
  msg2 "Setting mkinitcpio kernel name as ${_cpio_name}"
  echo ${_cpio_name} | install -Dm644 /dev/stdin "$modulesdir/pkgbase"
  # echo "${_major}-${CARCH}" | install -Dm644 /dev/stdin "$modulesdir/kernelbase"
 
  # add kernel version
  local _kver=`echo $pkgbase | sed "s/linux-//g;s/\b\(.\)/\u\1/g"`
  msg2 "Adding .kver as ${_kver}"
  echo "${pkgver}-${pkgrel}-${_kver} x64" | install -Dm644 /dev/stdin "${pkgdir}/boot/${pkgbase}.kver"

  msg2 "Installing modules..."
  make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 modules_install

  # remove build and source links
  rm "$modulesdir"/{source,build}
}

_package-headers() {
  pkgdesc="Header files and scripts for building modules for ${pkgbase} kernel"
  provides=()
  replaces=()
  conflicts=()
  depends=(pahole)

  cd linux-${_major}
  local builddir="$pkgdir/usr/lib/modules/$(<version)/build"

  msg2 "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
  cp -t "$builddir" -a scripts

  # add objtool for external module building and enabled VALIDATION_STACK option
  install -Dt "$builddir/tools/objtool" tools/objtool/objtool

  # add xfs and shmem for aufs building
  mkdir -p "$builddir"/{fs/xfs,mm}

  msg2 "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/x86" -a arch/x86/include
  install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # http://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # http://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  msg2 "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  msg2 "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */x86/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  msg2 "Removing documentation..."
  rm -r "$builddir/Documentation"

  msg2 "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  msg2 "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  msg2 "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -bi "$file")" in
      application/x-sharedlib\;*)      # Libraries (.so)
        strip -v $STRIP_SHARED "$file" ;;
      application/x-archive\;*)        # Libraries (.a)
        strip -v $STRIP_STATIC "$file" ;;
      application/x-executable\;*)     # Binaries
        strip -v $STRIP_BINARIES "$file" ;;
      application/x-pie-executable\;*) # Relocatable binaries
        strip -v $STRIP_SHARED "$file" ;;
    esac
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  msg2 "Stripping vmlinux..."
  strip -v $STRIP_STATIC "$builddir/vmlinux"
  msg2 "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"
}

pkgname=("${pkgbase}" "${pkgbase}-headers")
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package${_p#$pkgbase}")
    _package${_p#$pkgbase}
  }"
done
