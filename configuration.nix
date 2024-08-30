{ inputs, config, lib, pkgs, meta, ... }:

{
  imports =
    [
      inputs.sops-nix.nixosModules.sops
    ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "root" "@wheel" ];
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;
    # Secrets
    secrets."rancher_token" = {};
  };

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = false;
  boot.initrd.systemd.enable = true;

  networking.hostName = meta.hostname;
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker.logDriver = "json-file";

  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.sops.secrets."rancher_token".path; 
    extraFlags = toString ([
	    "--write-kubeconfig-mode \"0644\""
	    "--cluster-init"
	    "--disable servicelb"
	    "--disable traefik"
	    "--disable local-storage"
    ] ++ (if meta.hostname == "node-1" then [] else [
	      "--server https://node-1:6443"
    ]));
    clusterInit = (meta.hostname == "node-1");
  };

  # services.openiscsi = {
  #   enable = true;
  #   name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
  # };

  users.users.cluster = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Created using mkpasswd -m sha-512
    hashedPassword = "$6$485aln9uSLRPVjcA$BOZJAKC4TjYBSJxx86dPxFIUu79ccapg2ky.vLiPSSaF.D4I0B4xY52B3kSvRI1Xnb4JnxhF5A1K9WOXXt632.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFAapmuD0l/rfYUK1fpfgDkrEPQQF2skVLRsmN6P/r6"
    ];
  };

  environment.systemPackages = with pkgs; [
     vim
     k3s
     cifs-utils
     nfs-utils
     git
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall.enable = false;
  networking.hosts = {
    "10.0.1.210" = ["node-1"];
    "10.0.1.211" = ["node-2"];
    "10.0.1.212" = ["node-3"];
  };
  # Set Static IPs
  networking.interfaces.enp6s18.useDHCP = false;
  networking.defaultGateway = "10.0.1.1";
  networking.nameservers = [ "1.1.1.1" "9.9.9.9" ];
  networking.interfaces.enp6s18.ipv4.addresses =
    if meta.hostname == "node-1" then [{
      address = "10.0.1.210";
      prefixLength = 24;
    }] else if meta.hostname == "node-2" then [{
      address = "10.0.1.211";
      prefixLength = 24;
    }] else if meta.hostname == "node-3" then [{
      address = "10.0.1.212";
      prefixLength = 24;
    }] else [];

  system.stateVersion = "24.05";

}