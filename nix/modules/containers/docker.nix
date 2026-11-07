{ pkgs, ... }:

{
  virtualisation.docker.enable = true;
  users.users.janz.extraGroups = [ "docker" ];

  environment.systemPackages = [ pkgs.docker-compose ];
}
