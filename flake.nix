{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      lib = nixpkgs.lib;
    in
    {
      # curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
      # nix --extra-experimental-features "flakes nix-command" shell nixpkgs#nixos-install-tools
      # nixos-generate-config --no-filesystems --show-hardware-config
      nixosConfigurations.aurora = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };

        modules = [
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          ./disko.nix
          ./hardware-configuration.nix
          ./nix-settings.nix
          ./configuration.nix
          ./ss14.nix
          ./misc/misc.nix
          ./misc/ripgrep.nix
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.root = { config, lib, ... }: {
              imports = [
                ./home-manager/atuin.nix
                ./home-manager/delta.nix
                ./home-manager/starship.nix
              ];

              home.stateVersion = "26.11";
            };
          }
        ];
      };
    };
}
