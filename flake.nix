{
  description = "copilot";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs;
            [ elixir erlang erlang-ls nodejs-16_x ]
            ++ lib.optional stdenv.isLinux inotify-tools
            ++ lib.optionals stdenv.isDarwin
            (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);

          shellHook = ''
            mkdir -p ./.elixir/mix
            mkdir -p ./.elixir/hex

            export MIX_HOME=$PWD/.elixir/mix
            export HEX_HOME=$PWD/.elixir/hex

            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$HEX_HOME/bin:$PATH

            export LANG=en_US.UTF-8
            export ERL_AFLAGS="-kernel shell_history enabled"
          '';
        };
      });
}
