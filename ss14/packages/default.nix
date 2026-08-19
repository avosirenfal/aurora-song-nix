{
  pkgs ? import <nixpkgs> { },
}:
{
  ss14-watchdog = pkgs.callPackage ./watchdog.nix { };
  robust-cdn = pkgs.callPackage ./robust-cdn.nix { };
  ss14-admin = pkgs.callPackage ./admin.nix { };
}
