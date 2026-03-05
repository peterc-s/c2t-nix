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

      bastoken = pkgs.stdenv.mkDerivation {
        pname = "bastoken";
        version = "unstable-2020-09-20";

        src = pkgs.fetchFromGitHub {
          owner = "KrisKennaway";
          repo = "bastoken";
          rev = "7ce2d6a82ea64e7dcc2cb0ddb7eec4b7c6adfa69";
          hash = "sha256-U6ElcdcviB2cYWi3Vx6uCFczk3Q6q7yArZHAs+MvL+E=";
        };

        dontBuild = true;
        dontConfigure = true;

        nativeBuildInputs = [
          pkgs.makeWrapper
        ];

        installPhase = ''
          runHook preInstall

          install -Dm755 bastoken.py $out/lib/bastoken/bastoken.py
          makeWrapper ${pkgs.python3}/bin/python3 $out/bin/bastoken \
            --add-flags "$out/lib/bastoken/bastoken.py"

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Tokenizer for AppleSoft BASIC";
          homepage = "https://github.com/KrisKennaway/bastoken";
          platforms = platforms.all;
          mainProgram = "bastoken";
          license = licenses.bsd2;
        };
      };

      basic2tape = pkgs.writeShellScriptBin "basic2tape" ''
        #
        # basic2tape - tokenize Applesoft BASIC and convert to
        # audio for loading on an Apple II via cassette
        #
        # Usage: basic2tape <input.apl> <output.wav|aif>

        prog=''${0##*/}

        usage() {
        	cat <<-USAGE
        	Usage: $prog <input.apl> <output.wav|aif>

        	Tokenizes an Applesoft BASIC text file and converts
        	it to audio suitable for loading on an Apple II via
        	cassette.
        	USAGE
        }

        if (($# != 2)); then
        	usage >&2
        	exit 1
        fi

        input=$1
        output=$2

        if [[ ! -f $input ]]; then
        	echo "$prog: input file '$input' not found" >&2
        	exit 1
        fi

        tmpdir=$(mktemp -d) || exit 1

        cleanup() {
        	rm -rf "$tmpdir"
        }
        trap cleanup EXIT

        tokenized=$tmpdir/tokenized.bas

        echo "tokenizing $input..."
        ${bastoken}/bin/bastoken "$input" "$tokenized" || exit 1

        echo "generating audio $output..."
        ${c2t}/bin/c2t-96h -2 "$tokenized",801 "$output" || exit 1

        echo 'done!'
      '';
    in {
      packages = {
        inherit c2t bastoken basic2tape;
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
        bastoken = {
          type = "app";
          program = "${bastoken}/bin/bastoken";
        };
        basic2tape = {
          type = "app";
          program = "${basic2tape}/bin/basic2tape";
        };
        default = self.apps.${system}.c2t;
      };
    });
}
