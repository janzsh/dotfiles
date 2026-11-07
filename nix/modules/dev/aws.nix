{ pkgs, ... }:

{
  # AWS CLI v2. Las credenciales se cargan con `aws configure` (o
  # `aws configure sso`) y quedan en ~/.aws/, fuera de este repo.
  home.packages = [ pkgs.awscli2 ];
}
