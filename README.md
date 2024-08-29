To build:

go into iso folder
docker run --platform=linux/amd64 --rm -it -v $PWD:/out -w=/out nixos/nix

export NIX_CONFIG=$'filter-syscalls = false\nexperimental-features = nix-command flakes'
nix build .#nixosConfigurations.exampleIso.config.system.build.isoImage
mv result/iso/nixos-24.05.20240827.36bae45-x86_64-linux.iso .