{ pkgs, ... }:

{
  # Solo el CLI/servidor local, arrancado a mano con `ollama serve`.
  # Si se quiere el daemon siempre activo con aceleración GPU, usar
  # services.ollama a nivel de sistema en vez de esto.
  home.packages = [ pkgs.ollama ];
}
