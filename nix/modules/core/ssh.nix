{ ... }:

{
  services.openssh.enable = true;
  programs.ssh.startAgent = true;
  # GNOME habilita gcr-ssh-agent por defecto y choca con el agente de OpenSSH.
  services.gnome.gcr-ssh-agent.enable = false;
}
