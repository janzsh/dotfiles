{ pkgs, ... }:

{
  home.packages = [ pkgs.gh ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "janzsh";
      user.email = "jczp.020401@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
    includes = [
      {
        condition = "gitdir:~/Documents/efRouting/";
        contents.user = {
          name = "ef-juanzu";
          email = "jzuniga@efrouting.com";
        };
      }
    ];
  };
}
