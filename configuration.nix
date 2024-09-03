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
    hashedPassword = "$6$zBd4jLFLxMSwywE/$zoEu2GfCM/z3qq4cdRGdHM84CpuGSSVMMqFwy2xv8r2jCmp6VtiDjry6ILaG5aObV.d/yD41zPWfwFBBaX2LB/";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFAapmuD0l/rfYUK1fpfgDkrEPQQF2skVLRsmN6P/r6"
    ];
  };
  security.sudo.extraRules = [{
      users = ["cluster"];
      commands = [{
        command = "ALL";
        options = ["NOPASSWD" "SETENV"];
      }];
  }];

  environment.systemPackages = with pkgs; [
     vim
     k3s
     cifs-utils
     nfs-utils
     git
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  security.pam = {
    sshAgentAuth.enable = true;
    services.sudo.sshAgentAuth = true;
  };

  networking.firewall.enable = false;
  networking.hosts = builtins.listToAttrs (map (node: {
   name = node.ip;
   value = [ node.name ];
  }) meta.all_nodes);
  # # Set Static IP
  networking.interfaces.enp6s18.useDHCP = false;
  networking.defaultGateway = "10.0.1.1";
  networking.nameservers = [ "10.0.1.3" "1.1.1.1" "9.9.9.9" ];
  networking.interfaces.enp6s18.ipv4.addresses = [{
    address = meta.ip_address;
    prefixLength = 24;
  }];

  system.stateVersion = "24.05";

}