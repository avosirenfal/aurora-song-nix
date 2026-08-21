{
  programs.bash.enable = true;
  programs.atuin = {
    enable = true;

    enableBashIntegration = true;
    enableFishIntegration = true;

    # disable atuin for up arrow so each shell has its own history (via normal history)
    flags = [
      "--disable-up-arrow"
    ];

    # atuin generates a config file on first run, we can overwrite it
    forceOverwriteSettings = true;

    settings = {
      auto_sync = false;
      update_check = false;
      search_mode = "fuzzy";
    };
  };
}
