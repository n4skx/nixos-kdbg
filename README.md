# nixos-kdbg
My configuration for kernel debugging in NixOS, with nested virtualization support.

# NixOS configuration
## Bootloader
Change `kvm_intel` to `kvm_amd` if you are using a AMD processor.

```
boot = {
	loader = {
		systemd-boot.enable = true;
 		efi.canTouchEfiVariables = true;
	};
	extraModprobeConfig = "options kvm_intel nested=1"; # HERE
};
```

## Enable libvirt
`vhostUserPackages = [ pkgs.virtiofsd ];` is optional.

```
virtualisation.libvirtd = {
  enable = true;
  qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
    swtpm.enable = true;
    ovmf = {
      enable = true;
      packages = [(pkgs.OVMF.override {
        secureBoot = true;
        tpmSupport = true;
      }).fd];
    };
    vhostUserPackages = [ pkgs.virtiofsd ];
  };
};
```

Now add yourself to `libvirtd` group:
`
users.users.<your-username>.extraGroups = [ "libvirtd" ];
`

# Preparing VM
This section is mostly stolen from nixos.wiki/wiki/Kernel_Debugging_with_QEMU.

## Clone
First, grab linux kernel source code:
```
$ git clone https://github.com/torvalds/linux.git
```

## Dependencies
After successfully cloning, create a `shell.nix` in the same directory, with the following content:
```
{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "linux-kernel-build";
  nativeBuildInputs = with pkgs; [
    getopt
    flex
    bison
    gcc
    gnumake
    bc
    pkg-config
    binutils
  ];
  buildInputs = with pkgs; [
    elfutils
    ncurses
    openssl
    zlib
    pwndbg
  ];
}
```

Enter nix shell running:
```
$ nix-shell shell.nix 
```

> It's highly recommended to spawn a tmux right after entering nix-shell, doing so will prevent massive nix-shell usage.

## Generate KVM config
Run the following:
```
$ make mrproper
$ make defconfig kvm_guest.config
$ ./scripts/config --set-val DEBUG_INFO y --set-val DEBUG y  --set-val GDB_SCRIPTS y --set-val DEBUG_DRIVER y
$ make -j $(nproc)
```

> This section assumes that you are under nix-shell. 
> I had to run `./scripts/config -e DEBUG_INFO_DWARF5` due to some weird errors when using gdb, that may be your case too. See: github.com/deepseagirl/easylkb/issues/4

## Create a bootable NixOS image
Grab a copy of `nixos-image.nix` and `nixos-config.nix` from this repository to your current directory and run:
```
$ nix-build
$ install -m644 result/nixos.qcow2 qemu-image.img
```

## Launch 
Run the following:
```
$ qemu-system-x86_64 -s -S \
    -kernel arch/x86/boot/bzImage \
    -hda qemu-image.img \
    -append "root=/dev/sda console=ttyS0 nokaslr" \
    -enable-kvm \
    -nographic
```

### Attach gdb
In another terminal instance (or tmux panel), in the linux source directory, run the following:
```
# pwngdb -ex "target remote :1234" ./vmlinux
```

> Sudo is required for page table tranlation.

Now you should have a working kernel debugging setup :).
