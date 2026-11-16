{ secrets, ... }:
{
  users.users.jannis = {
    isNormalUser = true;
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [ secrets.SSH_KEYS.lannitz.public ];
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    linger = true;
  };
  security.sudo.wheelNeedsPassword = false;
}
