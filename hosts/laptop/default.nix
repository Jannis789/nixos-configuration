{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  networking.hostName = "laptop";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      mesa
      vulkan-loader
      vulkan-tools
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
    ];
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.jannis.openssh.authorizedKeys.keyFiles = [
    "${inputs.secrets}/ssh-authorized-keys"
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];
}
