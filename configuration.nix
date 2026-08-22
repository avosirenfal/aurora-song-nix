{
  config,
  pkgs,
  lib,
  ...
}:
{
  networking.hostName = "aurora";
  networking.hostId = "fc913c8c";
  boot.zfs.forceImportRoot = true;

  networking = {
    networkmanager.enable = false;
    useDHCP = true;
    firewall.enable = false;
    nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];
  };

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 7;
      editor = false;
      # TODO: sudo efibootmgr --create --disk /dev/whatever --part 1 --label "Boot Fallback" --loader '\EFI\systemd\systemd-bootx64.efi'
      extraInstallCommands = ''
        ${pkgs.rsync}/bin/rsync -a --delete /boot/ /boot-fallback/
      '';
    };

    efi.canTouchEfiVariables = true;
    timeout = 5;
  };

  boot.initrd.systemd.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  boot.zfs.package = pkgs.zfs_2_4;

  boot.kernelModules = [ "tcp_bbr" ];

  boot.kernel.sysctl = {
    # with ZFS we don't want the kernel paging memory
    # out to swap unnecessarily
    "vm.swappiness" = 10;
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.consoleLogLevel = 4;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "prohibit-password";
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHWKBImusn6Zygbveij4txIhSAlXVKVp3AjPt3R0OsI ember@lunitari"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCeQvwr2ZL7Z/TTJ3SELE60Zpa4sRLWTtd+fV3gs/ZtVJk0G4GekXCXCvkSdcwCB3nXDg2WUd3MRG9WfWh01/HiTRsnrXnRNEL3Ofab0LNduxWU3neK0IcokS/5RmRlwFAwd7aROolwcbfhJ8WQzMyTI1YZhLIiyeVRDzAX6YkJ71BO8Nl9pVZkdq8W2Is0zp9m3RYJq1/YyWsy65NSe/JdyMnHaPbdUniOQr2dc7R7JoYkP1lPPVIP8N1lP0XCv06acQpnwV/V3R+QkepThb+TeqShEeH5isGUocWgjVf0yahM16Xw6ubOSpz1dgPPIzWrYz43AYOVtfwhp2bATL9OYpPpac+uDeUXVgADiNUjQYGQC7MCoUCJRq/lNlXI17gP40zT9XwEpO5W8E/yNO+YtSwxQ+XYOmp/5FObv+CMSpdh0mVC95FBnMcl1/jnKj89je5i0kZRUc9cwM9Baf3QfmxxPW+GXWYrz5DEZ/PP+fKiGeGpX1si8ZXiTHGWbIU= buda@DESKTOP-R1OAAQ0"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICN94LO/wo5qR92Ez6y7KgltSqM7R263h3K72zgjVuqa falcon@somewhere"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuGkGV7VSXpzeDrQObEcW1163hw6mMM+gXLkyqtNyyj nessa@DESKTOP-0SR7SQG"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAILqWyytikWxOPm8+WouEwOowWotumXyKiFsxs+t778etAAAAB3NzaDp5azA= sol yk0"
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIMGejtdz+7zLQf6Yfbx/uLlxZ3C30l6Xlmqqht3AqnzDAAAAB3NzaDp5azE= sol yk1"
  ];

  # disable useless coredumps, they're not relevant for us
  systemd.coredump = {
    enable = true;
    settings.Coredump = {
      Storage = "none";
      ProcessSizeMax = "0";
    };
  };

  environment.systemPackages = with pkgs; [
    git
    ripgrep
    fd
    jujutsu
    htop
    iotop
    (pkgs.writeShellScriptBin "nxr" ''
      exec sudo nixos-rebuild --flake /root/nixos#aurora switch "$@"
    '')
  ];

  system.stateVersion = "26.11";
}
