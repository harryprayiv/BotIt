{
  # Override nixpkgs to use the latest set of node packages
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.systems.url = "github:nix-systems/default";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    systems,
  }:
    flake-utils.lib.eachSystem (import systems)
    (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
      start = pkgs.writeShellScriptBin "start" ''
        settings=$(cat config.yml)
        echo "current settings are:"
        echo $settings
        npm run start -- --cron "*/20 * * * *"
      '';

      build = pkgs.writeShellApplication {
        name = "build";
        runtimeInputs = with pkgs; [nodejs];
        text = "echo Building! && npm run build";
      };

      name = "Botlt";
    in {
      devShells.default = pkgs.mkShell {
        inherit name;
        packages = with pkgs; [
          build
          start
        ];
        buildInputs = [
          pkgs.nodejs
          pkgs.nodePackages.pnpm
          pkgs.nodePackages.typescript
          pkgs.nodePackages.typescript-language-server
        ];

        shellHook = ''
          export NIX_SHELL_NAME="Botlt"
          echo "Welcome to the devShell!"
          echo "To run the build function, type: run_build"
          echo "To start the bot on a 20 min cron, type: run_cron"
        '';
      };
    });
}
