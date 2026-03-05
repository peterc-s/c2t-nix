{
  description = "c2t - Retro Code (Apple II, Cosmac VIP) to Tape/Text";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachSystem ["x86_64-linux" "aarch64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
      };

      c2t = pkgs.stdenv.mkDerivation {
        pname = "c2t";
        version = "0.997-unstable";

        src = pkgs.fetchFromGitHub {
          owner = "datajerk";
          repo = "c2t";
          rev = "76c7a64c388c850db8bc9705be6ef52f04b2abd8";
          hash = "sha256-2O+J+Hccmzx7W5bSxkDQt3gXmM9xBETdSkpIUHcNhaE=";
        };

        dontConfigure = true;

        buildPhase = ''
          runHook preBuild

          mkdir -p bin
          $CC -Wall -Wno-strict-aliasing -Wno-unused-value -Wno-unused-function -I. -O3 -o bin/c2t c2t.c -lm
          $CC -Wall -Wno-strict-aliasing -Wno-unused-value -Wno-unused-function -I. -O3 -o bin/c2t-96h c2t-96h.c -lm

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          install -Dm755 bin/c2t $out/bin/c2t
          install -Dm755 bin/c2t-96h $out/bin/c2t-96h

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "c2t - Retro Code (Apple II, Cosmac VIP) to Tape/Text";
          homepage = "https://github.com/datajerk/c2t";
          platforms = ["x86_64-linux" "aarch64-linux"];
          mainProgram = "c2t";
          license = licenses.bsd3;
        };
      };
    in {
      packages = {
        inherit c2t;
        default = c2t;
      };

      apps = {
        c2t = {
          type = "app";
          program = "${c2t}/bin/c2t";
        };
        c2t-96h = {
          type = "app";
          program = "${c2t}/bin/c2t-96h";
        };
        default = self.apps.${system}.c2t;
      };
    });
}
