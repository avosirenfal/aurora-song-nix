{
  programs.bash.initExtra = ''
    _CURRENT_HOST="''${HOSTNAME:-$(hostname)}"

    if [ "$EUID" -eq 0 ]; then
      export STARSHIP_HOST_ROOT="$_CURRENT_HOST"
      unset STARSHIP_HOST_USER
    else
      export STARSHIP_HOST_USER="$_CURRENT_HOST"
      unset STARSHIP_HOST_ROOT
    fi
  '';

  programs.bash.enable = true;
  programs.starship = {
    enable = true;
    enableBashIntegration = true;

    settings = {
      add_newline = false;

      line_break = {
        disabled = true;
      };

      format = "(\n$cmd_duration\n)\\[$nix_shell$username\${env_var.host_root}\${env_var.host_user} $directory\\]$character";

      nix_shell = {
        format = "[$symbol]($style)";
        symbol = "* ";
        style = "bold cyan";
      };

      username = {
        show_always = true;
        style_user = "bold green";
        style_root = "bold red";
        format = "[$user]($style)";
      };

      hostname = {
        disabled = true;
      };

      env_var = {
        host_user = {
          variable = "STARSHIP_HOST_USER";
          style = "bold green";
          format = "[@$env_value]($style)";
        };

        host_root = {
          variable = "STARSHIP_HOST_ROOT";
          style = "bold red";
          format = "[@$env_value]($style)";
        };
      };

      directory = {
        format = "[$path](bold blue)";
        truncation_length = 0;
        truncate_to_repo = false;
      };

      character = {
        success_symbol = "[\\$](bold white)";
        error_symbol = "[\\$](bold red)";
      };
    };
  };
}
