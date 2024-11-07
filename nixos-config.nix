{ pkgs, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  networking.firewall.enable = false;

  boot = {
    isContainer = true;
    initrd.enable = false;

    loader = {
      grub.enable = false;
      initScript.enable = true;
    };
  };

  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };

  services = {
    getty = {
      helpLine =
        "  Small kernel exploitation box.\n\n  Login with root and empty password.\n  If you are connect via serial console:\n  Type Ctrl-a c to switch to the qemu console\n  and `quit` to stop the VM.\n";

      autologinUser = lib.mkDefault "root";
    };
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        "PermitEmptyPasswords" = "yes";
      };
    };
  };

  users.extraUsers = {
    root = {
      #shell = pkgs.fish;
      initialHashedPassword = "";
    };
  };

  console = {
    enable = true;
    keyMap = "br-abnt2";
  };

  systemd.services = { "serial-getty@ttyS0".enable = true; };

  programs = {
    bash.enableCompletion = false;
    command-not-found.enable = false;
  };
}
