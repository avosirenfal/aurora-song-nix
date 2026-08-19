{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  nix-update-script,
}:
buildDotnetModule {
  pname = "SS14.Watchdog";
  version = "v1.0";

  src = fetchFromGitHub {
    owner = "space-wizards";
    repo = "SS14.Watchdog";
    tag = "v1.0";
    hash = "sha256-8xau8Dy5lkWJkBxu3UweDdlE3MeTelPzlsQGBvuQSxY=";
  };

  passthru.updateScript = nix-update-script { };

  projectFile = "SS14.Watchdog/SS14.Watchdog.csproj";
  # $(nix-build default.nix -A ss14-watchdog.fetch-deps --no-out-link)
  nugetDeps = ./watchdog-deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  executables = [ "SS14.Watchdog" ];

  meta = with lib; {
    homepage = "https://github.com/space-wizards/SS14.Watchdog";
    license = licenses.mit;
    mainProgram = "SS14.Watchdog";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
