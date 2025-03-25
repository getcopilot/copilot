{
  description = "copilot";

  nixConfig = {
    extra-substituters = [
      "https://copilot.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];

    extra-trusted-public-keys = [
      "copilot.cachix.org-1:S3bdMN1HiDuXaJsh88/Tb0ZjkK3QPmYJRny9hViEQWk="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt.url = "github:numtide/treefmt-nix";
    treefmt.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      imports = with inputs; [ treefmt.flakeModule ];

      perSystem = { config, pkgs, lib, ... }: {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [ cachix elixir just yamllint nodejs_22 nodePackages_latest.pnpm ]
            ++ [ config.treefmt.build.wrapper ]
            ++ (builtins.attrValues config.treefmt.build.programs)
            ++ lib.optionals stdenv.isLinux [ inotify-tools ]
            ++ lib.optionals stdenv.isDarwin
            (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);

          shellHook = ''
            export LANG="en_US.UTF-8"
            export ERL_AFLAGS="-kernel shell_history enabled"
            export MIX_ENV="dev"

            export MIX_HOME="$PWD/.elixir/mix"
            export HEX_HOME="$PWD/.elixir/hex"

            export PATH="$MIX_HOME/bin:$PATH"
            export PATH="$HEX_HOME/bin:$PATH"
          '';
        };

        treefmt.config = {
          projectRootFile = "flake.nix";
          programs = {
            deadnix.enable = true;
            nixfmt = {
              enable = true;
              package = pkgs.nixfmt-classic;
            };
            prettier.enable = true;
          };
          settings.formatter = {
            elixir = {
              command = lib.getExe' pkgs.elixir "mix";
              options = [ "format" ];
              includes = [ "*.ex" "*.exs" "*.heex" ];
            };
            justfile = {
              command = lib.getExe pkgs.just;
              options = [ "--unstable" "--fmt" "--justfile" ];
              includes = [ "Justfile" ];
            };
            yamllint = {
              command = lib.getExe pkgs.yamllint;
              includes = [ "*.yaml" "*.yml" ];
              excludes = [ "apps/copilot_web/assets/pnpm-lock.yaml" ];
            };
          };
        };
      };
    };
}
