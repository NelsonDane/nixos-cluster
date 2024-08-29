{ config, lib, pkgs, meta, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
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
    tokenFile = /var/lib/rancher/k3s/server/token;
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
    # Created using mkpasswd
    hashedPassword = "$6$485aln9uSLRPVjcA$BOZJAKC4TjYBSJxx86dPxFIUu79ccapg2ky.vLiPSSaF.D4I0B4xY52B3kSvRI1Xnb4JnxhF5A1K9WOXXt632.";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAC3NzaC1lZDI1NTE5AAAAINFAapmuD0l/rfYUK1fpfgDkrEPQQF2skVLRsmN6P/r6"
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

  system.stateVersion = "24.05";

}