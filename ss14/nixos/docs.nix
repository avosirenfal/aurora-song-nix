{
  pkgs ? import <nixpkgs> { },
}:

let
  dummyModule = { lib, ... }: {
    options = {
      assertions = lib.mkOption {
        type = lib.types.raw;
        description = "shim";
        default = [ ];
      };
      users = lib.mkOption {
        type = lib.types.raw;
        description = "shim";
        default = { };
      };
      systemd = lib.mkOption {
        type = lib.types.raw;
        description = "shim";
        default = { };
      };
      services.postgresql = lib.mkOption {
        type = lib.types.raw;
        description = "shim";
        default = { };
      };
      services.prometheus = lib.mkOption {
        type = lib.types.raw;
        description = "shim";
        default = { };
      };
    };
  };

  eval = pkgs.lib.evalModules {
    modules = [
      ./robust-cdn.nix
      ./watchdog.nix
      ./servers.nix
      dummyModule
    ];
    specialArgs = { inherit pkgs; };
  };

  optionsDoc = pkgs.nixosOptionsDoc {
    options = eval.options;
  };

in
pkgs.stdenv.mkDerivation {
  name = "ss14-nixos-docs";
  src = optionsDoc.optionsCommonMark;
  dontUnpack = true;
  nativeBuildInputs = [ pkgs.pandoc ];

  installPhase = ''
    mkdir -p $out
    pandoc $src \
      --standalone \
      --metadata title="Space Station 14 NixOS Options" \
      -o $out/index.html
  '';
}
