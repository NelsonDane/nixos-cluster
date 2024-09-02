# Clarkson ECE Lab Cluster

Built with NixOS and Kubernetes.


## Build NixOS ISO
If building with Apple Silicon Mac (or other non x86_64 architecture), see [this post](https://blog.nelsondane.me/posts/build-nixos-iso-on-silicon-mac/). Otherwise, follow the steps below.
```bash
cd iso
nix build .#nixosConfigurations.exampleIso.config.system.build.isoImage
```
Resulting ISO will be in the `result` directory. Then burn that ISO to a USB drive.

## Secrets Management
Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix). On creation, each node generates a key located at `/etc/ssh/ssh_host_ed25519_key.pub`. During the install, the key is converted to `age` and printed in the terminal. Copy this, and add it to the `.sops.yaml` file.

To create your own key for local development, generate an ssh key, and convert it to `age`:
```bash
nix-shell -p ssh-to-age --run 'cat /YOUR/KEY/PATH.pub | ssh-to-age'
```
Then add the output to the `.sops.yaml` file.

To update keys across all nodes, commmit the changes to the `.sops.yaml` file, and run the following command:
```bash
nix-shell -p sops --run "SOPS_AGE_KEY_FILE=./keys.txt sops updatekeys secrets/secrets.yaml"
```

update flake: nix flake update

## Adding a New Node
Make sure you have `nix` installed locally. Then:
1. Add the new IP in `configuration.nix`.
2. Add the new node to the `nodes` list in `flake.nix`.
3. Execute the following command:
```bash
SSH_PRIVATE_KEY="$(cat ./nixos_cluster)"$'\n' nix run github:nix-community/nixos-anywhere --extra-experimental-features "nix-command flakes" -- --flake '.#node-NUMBER' root@IP_ADDRESS
```
4. Copy the outputted `age` key to the `.sops.yaml` file. See [Secrets Management](#secrets-management) for more information.

## Updating the Cluster with New/Changed Configuration
You need at least one node with the repository cloned. Then, to update the current node:
```bash
sudo nixos-rebuild switch --flake '.#node-NUMBER'
```

Then to update each node in the cluster:
```bash
nixos-rebuild switch --flake '.#node-NUMBER' --use-remote-sudo --target-host cluster@node-NUMBER
```
This will also update secrets on each node.

## Update NixOS
To update NixOS on all nodes, run the following command:
```bash
nix flake update
```
Commit, then update each node. See [Updating the Cluster with New/Changed Configuration](#updating-the-cluster-with-newchanged-configuration) for more information.
