{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [
      "root"
      "@wheel"
    ];

    auto-optimise-store = true;
  };

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nixpkgs.config.allowUnfree = true;

  # make ad-hoc commands (`nix shell nixpkgs#whatever`, `nix run nixpkgs#whatever`)
  # resolve `nixpkgs` to the exact revision pinned by this flake
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # same for legacy `nix-shell -p foo` / `<nixpkgs>`
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
}
