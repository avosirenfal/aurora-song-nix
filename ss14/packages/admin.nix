{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
  nix-update-script,
}:
buildDotnetModule {
  pname = "SS14.Admin";
  version = "1.9.1";

  src = fetchFromGitHub {
    owner = "space-wizards";
    repo = "SS14.Admin";
    tag = "v1.9.1";
    hash = "sha256-CIdOLNCTi6c7wRegba+VvvZ0rvi+YL/QAGJ7Z1OZOUc=";
    fetchSubmodules = true;
  };

  passthru.updateScript = nix-update-script { };

  projectFile = "SS14.Admin/SS14.Admin.csproj";
  nugetDeps = ./admin-deps.json;

  dotnet-sdk = dotnetCorePackages.sdk_10_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_10_0;

  executables = [ "SS14.Admin" ];

  meta = with lib; {
    homepage = "https://github.com/space-wizards/SS14.Admin";
    license = licenses.mit;
    mainProgram = "SS14.Admin";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
