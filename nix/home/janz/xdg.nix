{ config, ... }:

{
  # Carpetas de usuario declarativas (antes las escribía xdg-user-dirs-update).
  xdg.userDirs = {
    enable = true;
    setSessionVariables = false;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
    templates = "${config.home.homeDirectory}/Templates";
    publicShare = "${config.home.homeDirectory}/Public";
    extraConfig.XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects";
  };

  # Aplicaciones por defecto (antes mimeapps.list lo reescribía Firefox a mano).
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/chrome" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";

      "inode/directory" = "org.gnome.Nautilus.desktop";
      "application/pdf" = "org.gnome.Papers.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "audio/mpeg" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";

      "x-scheme-handler/bruno" = "bruno.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
    };
  };
}
