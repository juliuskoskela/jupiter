{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use GRUB2 as the boot loader.
  # We don't use systemd-boot because Hetzner uses BIOS legacy boot.
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
    devices = [ "/dev/sda" "/dev/sdb" ];
  };

  networking.hostName = "hetzner";

  # The mdadm RAID1s were created with 'mdadm --create ... --homehost=hetzner',
  # but the hostname for each machine may be different, and mdadm's HOMEHOST
  # setting defaults to '<system>' (using the system hostname).
  # This results mdadm considering such disks as "foreign" as opposed to
  # "local", and showing them as e.g. '/dev/md/hetzner:root0'
  # instead of '/dev/md/root0'.
  # This is mdadm's protection against accidentally putting a RAID disk
  # into the wrong machine and corrupting data by accidental sync, see
  # https://bugzilla.redhat.com/show_bug.cgi?id=606481#c14 and onward.
  # We do not worry about plugging disks into the wrong machine because
  # we will never exchange disks between machines, so we tell mdadm to
  # ignore the homehost entirely.
  environment.etc."mdadm.conf".text = ''
    HOMEHOST <ignore>
  '';
  # The RAIDs are assembled in stage1, so we need to make the config
  # available there.
  boot.initrd.mdadmConf = config.environment.etc."mdadm.conf".text;

  # Network (Hetzner uses static IP assignments, and we don't use DHCP here)
  networking.useDHCP = false;
  networking.interfaces."enp0s31f6".ipv4.addresses = [
    {
      address = "65.108.33.170";
      # According to https://www.calculator.net/ip-subnet-calculator.html?cclass=any&csubnet=29&cip=65.108.33.170&ctype=ipv4&x=Calculate prefix lenght is 29.
      prefixLength = 29;
    }
  ];
  networking.interfaces."enp0s31f6".ipv6.addresses = [
    {
      address = "2a01:4f9:2b:2da::2";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway = "65.108.33.169";
  networking.defaultGateway6 = { address = "fe80::1"; interface = "enp0s31f6"; };
  networking.nameservers = [ "8.8.8.8" ];

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  users.users.root.openssh.authorizedKeys.keys = [
    # change this to your ssh key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7xenLdf7uvzzoRVnqW8JIiMbifv4Aok1jZb05MQrfQh3cAJb4BqffAfZ3LRT1vK9Y9zfKIgyx500Y+j85D32DB4E53k099paQHARcXuIw3KYVBiUQCy9XrSPJ0lePYH614feabsAYHs/pFni2LsWUPFOBOWmJa3BjvQE6RL9Y7wdk9s+P2G8IUqDmAp1vtjCCM++llCUYjLPMenJVkc7sLd1Vp6Yl9XnrsgGCaWYi8z6PRjTOs6MKCjmapiyY9KNdRiskdhLaJ1wJh+tPImqj3s1zksWzF82U19QT2Yj7FVQkGlJ25bfWRFJPtpWi/2QwDY4HKjdVl1SHwkldStmjFtBZ1RWHPkOsWfCogqzzQe85RSyrobB3HxWzrbkm3vJYDS/8jt++65BHF0o+Es4isLrrDp4gH+LF1TKaAoyRDIgwQ3KCfuEmXVIMD6feFOfi+G4Mo43VUdIZ0LDdPjf2ucQ5tTex5mez8HIs2mc3qfacl2xCjuhOoC3SBPHJ1w8= juliuskoskela@luna"
  ];


  services.openssh.enable = true;

  system.stateVersion = "23.11";

}
