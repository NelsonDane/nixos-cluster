{
  description = "Cluster NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: let
    # Define cluster nodes/IPs
    nodes = [
      { name = "node-1"; ip = "10.0.1.50"; }
      { name = "node-2"; ip = "10.0.1.51"; }
      { name = "node-3"; ip = "10.0.1.52"; }
      { name = "node-4"; ip = "10.0.1.53"; }
      { name = "node-5"; ip = "10.0.1.54"; }
    ];
  in {
    nixosConfigurations = builtins.listToAttrs (map (node: {
      name = node.name;
	    value = nixpkgs.lib.nixosSystem {
     	    specialArgs = {
            inherit inputs;
            meta = {
              hostname = node.name;
              ip_address = node.ip;
              all_nodes = nodes;
            };
          };
          system = "x86_64-linux";
          modules = [
              # Modules
	            disko.nixosModules.disko
	            ./hardware-configuration.nix
	            ./disko-config.nix
	            ./configuration.nix
	          ];
        };
    }) nodes);
  };
}
