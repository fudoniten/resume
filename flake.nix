{
  description = "Peter Selby's resume, typeset with LaTeX (moderncv)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # Only the TeX Live packages resume.tex actually needs, rather than
      # pulling in a multi-gigabyte scheme-full closure.
      texEnvFor = pkgs: pkgs.texliveSmall.withPackages (ps: with ps; [
        moderncv
        ragged2e
        etoolbox
        geometry
        lm
      ]);

      resumeFor = pkgs: pkgs.stdenvNoCC.mkDerivation {
        pname = "resume";
        version = "0-unstable-2026-09-09";

        # Only resume.tex is an input, so editing the README or the flake
        # itself does not invalidate the build.
        src = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = ./resume.tex;
        };

        nativeBuildInputs = [ (texEnvFor pkgs) ];

        # Make the PDF byte-for-byte reproducible: no build timestamp, and a
        # fixed document ID derived from SOURCE_DATE_EPOCH.
        env = {
          SOURCE_DATE_EPOCH = "0";
          FORCE_SOURCE_DATE = "1";
        };

        buildPhase = ''
          runHook preBuild
          # -halt-on-error makes a LaTeX error fail the build rather than
          # silently emitting a broken PDF. Two passes settle the layout.
          pdflatex -halt-on-error -interaction=nonstopmode resume.tex
          pdflatex -halt-on-error -interaction=nonstopmode resume.tex
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          install -Dm444 resume.pdf $out/resume.pdf
          runHook postInstall
        '';

        meta = {
          description = "Peter Selby's resume as a PDF";
          platforms = pkgs.lib.platforms.all;
        };
      };
    in
    {
      # nix build  ->  ./result/resume.pdf
      packages = forAllSystems (pkgs: rec {
        resume = resumeFor pkgs;
        default = resume;
      });

      # nix run  ->  drops a plain resume.pdf in the current directory,
      # which is easier to attach to an email than a store symlink.
      apps = forAllSystems (pkgs: rec {
        copy = {
          type = "app";
          meta.description = "Write resume.pdf into the current directory";
          program = pkgs.lib.getExe (pkgs.writeShellScriptBin "copy-resume" ''
            install -m644 ${resumeFor pkgs}/resume.pdf ./resume.pdf
            echo "wrote $PWD/resume.pdf"
          '');
        };
        default = copy;
      });

      # nix develop  ->  pdflatex on PATH for fast local iteration.
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = [ (texEnvFor pkgs) ];
        };
      });
    };
}
