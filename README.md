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

To create a `keys.txt` for local development, run the following command:
```bash
nix run nixpkgs#ssh-to-age -- -private-key -i ~/YOUR/KEY/PATH > keys.txt
```

To update keys across all nodes, commmit the changes to the `.sops.yaml` file, and run the following command:
```bash
nix-shell -p sops --run "SOPS_AGE_KEY_FILE=./keys.txt sops updatekeys secrets/secrets.yaml"
```

## Adding a New Node
Make sure you have `nix` installed locally. Then:
1. Add the new node and its IP to the in `flake.nix`.
2. Execute the following command:
```bash
SSH_PRIVATE_KEY="$(cat ./nixos_cluster)"$'\n' nix run github:nix-community/nixos-anywhere --extra-experimental-features "nix-command flakes" -- --flake '.#cluster-node-NUMBER' root@192.168.100.199
```
3. Once the node boots, run:
```bash
nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'
```
Copy the outputted `age` key to the `.sops.yaml` file and regenerate secrets, then update the node. See [Secrets Management](#secrets-management) for more information.

## Updating the Cluster with New/Changed Configuration
If you have the repository cloned on a node (working on changes without committing), then run to update from local source:
```bash
sudo nixos-rebuild switch --flake '.#cluster-node-NUMBER'
```

Then to update each node in the cluster:
```bash
sudo nixos-rebuild switch --flake '.#cluster-node-NUMBER' --use-remote-sudo --target-host cluster@cluster-node-NUMBER
```
This will also update secrets on each node.

To pull new changes from the repository without cloning, just run:
```bash
sudo nixos-rebuild switch --flake github:NelsonDane/clarkson-nixos-cluster#cluster-node-NUMBER
```

All nodes can ssh into each other using the included `ssh_config`. There is a key located in `.sops.yaml` that is available at `/run/secrets/cluster_talk`.

## Update NixOS
To update NixOS on all nodes, run the following command:
```bash
nix flake update
```
Commit, then update each node. See [Updating the Cluster with New/Changed Configuration](#updating-the-cluster-with-newchanged-configuration) for more information.

A GitHub Action runs this everyday at 3am automatically.

## Aliases
For convenience, the following aliases are available:
```bash
c -> clear
k -> kubectl
h -> helm
hf -> helmfile
```

## Kubernetes
For distributed storage, we use [Longhorn](https://longhorn.io/). To install Longhorn, run the following command:
```bash
cd helm
hf apply
```
To see the gui, go to `http://192.168.100.61` in your browser.

To get Metallb working, run the following command:
```bash
cd helm/kustomize
kubectl apply -k .
```

To see IPs:
```bash
k get svc -A
```

## Slurm
Slurm is configured using the [Slurm Helm Chart](https://github.com/NelsonDane/slurm-k8s-cluster). To pull the submodules for Slurm, run the following command:
```bash
git submodule update --init --recursive
```

Then to install Slurm, run:
```bash
cd helm/slurm-k8s-cluster
h install slurm slurm-cluster-chart
```
And then to apply changes after initial install, run:
```bash
h upgrade slurm slurm-cluster-chart
```

The Slurm GUI is available at `https://192.168.100.82`
