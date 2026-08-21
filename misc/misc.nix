{ lib, config, ... }: {
  # allow root to psql directly if postgres is enabled
  services.postgresql = {
    ensureUsers = [
      {
        name = "root";
        ensureClauses = {
          superuser = true;
          login = true;
        };
      }
    ];
  };

  programs.bash.interactiveShellInit = lib.mkIf config.services.postgresql.enable ''
    if [ "$USER" = "root" ]; then
      export PGDATABASE="postgres";
    fi
  '';
}
