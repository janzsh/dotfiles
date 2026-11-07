{ ... }:

{
  virtualisation.podman = {
    enable = true;
    # false a propósito: ya tenemos docker real (docker.nix), no queremos
    # que podman se alíe el socket/comando `docker` y choquen.
    dockerCompat = false;
  };
}
