{ config, pkgs, ... }:
let
  rg-delta = pkgs.writeShellScriptBin "rgd" ''
    export PATH="${pkgs.ripgrep}/bin:${pkgs.delta}/bin:$PATH"

    is_piped=0
    [ ! -t 1 ] && is_piped=1

    has_help=0
    has_bare=0
    new_args=()

    for arg in "$@"; do
      if [ "$arg" = "--help" ]; then
        has_help=1
        new_args+=("$arg")
      elif [ "$arg" = "--bare" ]; then
        has_bare=1
      else
        new_args+=("$arg")
      fi
    done

    if [ "$has_help" -eq 1 ] || [ "$has_bare" -eq 1 ] || [ "$is_piped" -eq 1 ]; then
      rg "''${new_args[@]}"
    else
      rg --json "''${new_args[@]}" | delta
    fi
  '';

  rg-fzf = pkgs.writeShellScriptBin "rgo" ''
    export PATH="${pkgs.ripgrep}/bin:${pkgs.fzf}/bin:${pkgs.bat}/bin:${pkgs.nano}/bin:$PATH"

    rg --json --line-number --no-heading --smart-case "$@" | delta --grep-output-type=classic | \
      fzf --ansi \
          --no-height \
          --margin=0 \
          --padding=0 \
          --border=none \
          --delimiter ':' \
          --extended \
          --preview 'bat --color=always --highlight-line {2} {1}' \
          --preview-window 'right,60%,border-left,+{2}+3/3:~3' \
          --bind "enter:execute(nano +{2} {1})"
  '';
in
{
  environment.systemPackages = with pkgs; [
    ripgrep
    rg-delta
    delta
    rg-fzf
    fzf
    bat
  ];

  environment.shellAliases = {
    rg = "rgd";
  };
}
