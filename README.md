To build:

go into iso folder
docker run --platform=linux/amd64 --rm -it -v $PWD:/out -w=/out nixos/nix

export NIX_CONFIG=$'filter-syscalls = false\nexperimental-features = nix-command flakes'
nix build .#nixosConfigurations.exampleIso.config.system.build.isoImage
mv result/iso/nixos-24.05.20240827.36bae45-x86_64-linux.iso .

update flake: nix flake update

Uses keys generated at creation. Convert to age:
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
nix-shell -p sops --run "SOPS_AGE_KEY_FILE=./keys.txt sops updatekeys secrets/secrets.yaml"

sudo nixos-rebuild switch --flake '.#node-1'

Then on node 1:
nixos-rebuild switch --flake '.#node-2' --target-host cluster@10.0.1.211
