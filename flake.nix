{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      disko,
    }:
    {
      # curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
      # nix --extra-experimental-features "flakes nix-command" shell nixpkgs#nixos-install-tools
      # nixos-generate-config --no-filesystems --show-hardware-config
      nixosConfigurations.aurora = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          disko.nixosModules.disko
          ./disko.nix
          ./hardware-configuration.nix
          ./nix-settings.nix
          ./configuration.nix
          ./ss14.nix
        ];
      };
    };
}
