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
      name = "Botlt";
      # systems = [
      #   "aarch64-darwin"
      #   "x86_64-darwin"
      #   "x86_64-linux"
      # ];
    in {
      devShells.default = pkgs.mkShell {
        inherit name;
        buildInputs = [
          pkgs.nodejs
          # You can set the major version of Node.js to a specific one instead
          # of the default version
          # pkgs.nodejs-19_x

          # You can choose pnpm, yarn, or none (npm).
          pkgs.nodePackages.pnpm
          # pkgs.yarn

          pkgs.nodePackages.typescript
          pkgs.nodePackages.typescript-language-server
        ];
        shellHook = ''
          export NIX_SHELL_NAME="Botlt"
          echo "Welcome to the devShell!"
          npm run build
          echo built
          echo .
          echo ..
          echo ...
          echo Auto-starting Bot on a 20 min cron...
          settings=$(cat config.yml)
          echo current settings are:
          echo $settings
          npm run start -- --cron "*/20 * * * *"
        '';
      };
    });
}
