{ ... }:
let
  mainDriveContent = boot_mountpoint: {
    type = "gpt";
    partitions = {
      ESP = {
        size = "2G";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = boot_mountpoint;
          mountOptions = [ "umask=0077" ];
        };
      };
      swap = {
        size = "8G";
        content = {
          type = "swap";
          randomEncryption = true;
        };
      };
      zfs = {
        size = "100%";
        content = {
          type = "zfs";
          pool = "zroot";
        };
      };
    };
  };
in
{
  # linux device names (e.g. "sda" from /dev/sda) are not guaranteed to be stable
  # upon reboot they can be ordered differently, such that what used to be /dev/sda
  # can now be /dev/sdb (or whatever)
  #
  # hypervisor virtual disks, e.g. /dev/xvda, /dev/vda, etc, ARE stable
  # if your target device is one of those, use it directly, like:
  #
  #     device = "/dev/xvda"
  #
  # otherwise to guarantee stable device targets use /dev/disk/by-id/... whenever
  # possible. to do this, first find the desired disk using:
  #
  #     lsblk -o NAME,MODEL,MOUNTPOINT
  #
  # then to go from a device name, like /dev/nvme0n1, to a udev device ID:
  #
  #     udevadm test /sys/class/block/nvme0n1 2>&1 | grep -i DEVLINKS
  #
  # you want /by-id/, NOT /by-diskseq/, /by-path/, etc
  disko.devices = {
    disk = {
      drive1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HCJQ-00B07_S63CNX0YA02975";
        content = mainDriveContent "/boot";
      };

      drive2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL2512HCJQ-00B07_S63CNX0YA02966_1";
        content = mainDriveContent "/boot-fallback";
      };
    };

    zpool.zroot = {
      type = "zpool";
      mode = "mirror";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        xattr = "sa";
        atime = "on";
        relatime = "on";
        compression = "zstd";
        mountpoint = "none";
      };

      datasets = {
        "root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
          mountOptions = [ "lazytime" ];
        };
        "nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
          mountOptions = [ "lazytime" ];
        };
        "home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
          mountOptions = [ "lazytime" ];
        };
        "tmp" = {
          type = "zfs_fs";
          mountpoint = "/tmp";
          options = {
            mountpoint = "legacy";
            reservation = "16G";
            sync = "disabled";
            xattr = "sa";
            atime = "off";
            redundant_metadata = "none";
            "com.sun:auto-snapshot" = "false";
          };
        };
      };
    };
  };
}
