{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first --git";
      la = "eza -la --icons --group-directories-first --git";
      tree = "eza --tree --icons";
      cat = "bat --paging=never";
      ".." = "cd ..";
      "..." = "cd ../..";
      gs = "git status -sb";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate -20";
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles#onirical";
    };

    initContent = ''
      # Tema dinámico (config/theme)
      export STARSHIP_CONFIG="$HOME/.cache/theme/starship.toml"
      _theme_reload() { [[ -r ~/.cache/theme/fzf.zsh ]] && source ~/.cache/theme/fzf.zsh }
      precmd_functions+=(_theme_reload)

      # Navegación
      setopt AUTO_CD INTERACTIVE_COMMENTS
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word

      # Completado insensible a mayúsculas y con menú
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu select
    '';
  };

  # Los colores de starship y fzf los genera `theme` (config/theme) en
  # ~/.cache/theme. Starship relee su config en cada prompt; fzf se re-source
  # en el hook precmd (ver initContent), así `theme set` aplica sin reabrir.
  programs.starship.enable = true;
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd" "cd" ];   # `cd` pasa a ser inteligente (cd foo salta por frecuencia)
  };

  # direnv + nix-direnv: carga el entorno de un flake/shell.nix al entrar al
  # directorio (`echo "use flake" > .envrc && direnv allow`) con caché.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.eza.enable = true;
  programs.bat = {
    enable = true;
    config.theme = "base16";
  };

  home.packages = [ pkgs.ripgrep pkgs.fd ];
}
