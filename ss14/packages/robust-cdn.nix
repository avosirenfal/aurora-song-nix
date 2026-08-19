{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  nix-update-script,
  libsodium,
  zstd,
}:
buildDotnetModule {
  pname = "Robust.Cdn";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "space-wizards";
    repo = "Robust.Cdn";
    tag = "v2.2.0";
    hash = "sha256-GSjk7UU/iBC3qaYAgypGHgqrjV+8KGPFS8yYzwPocC0=";
  };

  passthru.updateScript = nix-update-script { };

  projectFile = "Robust.Cdn/Robust.Cdn.csproj";
  nugetDeps = ./robust-cdn-deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  runtimeDeps = [
    libsodium
    zstd
  ];

  executables = [ "Robust.Cdn" ];

  meta = with lib; {
    homepage = "https://github.com/space-wizards/Robust.Cdn";
    license = licenses.mit;
    mainProgram = "Robust.Cdn";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
