{
  # Set `mkEnv` to choose whether to return a package or a development
  # environment. The default is to follow inNixShell.
  mkEnv ? null
, # Set `target` to choose the package from haskellPackages which will be
  # returned (eg. name of a liquidhaskell package).
  target ? "liquidhaskell_metapackage"
, # nixpkgs config
  config ? { allowBroken = true; }
}:
let
  nixpkgs = import (
    builtins.fetchTarball {
      # fetch latest nixpkgs https://github.com/NixOS/nixpkgs-channels/tree/nixos-20.03 as of Fri 11 Sep 2020 05:48:57 AM UTC
      url = "https://github.com/NixOS/nixpkgs-channels/archive/4bd1938e03e1caa49a6da1ec8cff802348458f05.tar.gz";
      sha256 = "0529npmibafjr80i2bhqg22pjr3d5qz1swjcq2jkdla1njagkq2k";
    }
  ) { inherit config; };
  # function to make sure a haskell package has z3 at build-time and test-time
  usingZ3 = pkg: nixpkgs.haskell.lib.overrideCabal pkg (old: { buildTools = old.buildTools or [] ++ [ nixpkgs.z3 ]; });
  # package set for haskell compiler version
  haskellCompilerPackages = nixpkgs.haskell.packages."ghc8101";
  # override package set to inject project components
  haskellPackages = haskellCompilerPackages.override (
    old: {
      all-cabal-hashes = nixpkgs.fetchurl {
        # fetch latest cabal hashes https://github.com/commercialhaskell/all-cabal-hashes/tree/hackage as of Fri 11 Sep 2020 05:48:57 AM UTC
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/fdf36e3692e7cd30da7b9da4b1d7b87eb14fe787.tar.gz";
        sha256 = "1qirm02bv3p11x2bjl72d62lj5lm4a88wg93fi272a8h7a8496wn";
      };
      overrides = self: super: with nixpkgs.haskell.lib; rec {
        # turn off tests and haddocks and version bounds by default
        mkDerivation = args: super.mkDerivation (
          args // { doCheck = false; doHaddock = false; jailbreak = true; }
        );
        # declare each of the packages contained in this repo
        ## LH support packages
        liquidhaskell = self.callCabal2nix "liquidhaskell" (nixpkgs.nix-gitignore.gitignoreSource [] ./.) {};
        liquid-fixpoint = overrideCabal (self.callCabal2nix "liquid-fixpoint" (nixpkgs.nix-gitignore.gitignoreSource [] ./liquid-fixpoint) {})
          (old: { preCheck = ''export PATH="$PWD/dist/build/fixpoint:$PATH"''; }); # bring the `fixpoint` binary into scope for tests run by nix-build
        # dependencies
        ## declare dependencies using the latest hackage releases as of Fri 11 Sep 2020 05:48:57 AM UTC
        hashable = self.callHackage "hashable" "1.3.0.0" {}; # ouch; requires recompilation of around 30 packages
        optics = self.callHackage "optics" "0.3" {};
        optics-core = self.callHackage "optics-core" "0.3.0.1" {};
        optics-extra = self.callHackage "optics-extra" "0.3" {};
        optics-th = self.callHackage "optics-th" "0.3.0.2" {};

        liquidhaskell_metapackage = nixpkgs.haskell.lib.overrideCabal super.hello (
          old: {
            buildDepends = old.buildDepends or [] ++ projectPackages;
            passthru = { inherit nixpkgs; inherit haskellPackages; inherit projectPackages; };
          }
        );
      };
    }
  );
  # packages part of this local project
  projectPackages = with haskellPackages; [
    liquid-fixpoint
    liquidhaskell
  ];
  # derivation to build
  drv = haskellPackages."${target}";
in
if
  (mkEnv != null && mkEnv) || (mkEnv == null && nixpkgs.lib.inNixShell)
then
  drv.env.overrideAttrs
    (old: { nativeBuildInputs = old.nativeBuildInputs ++ [ nixpkgs.cabal-install nixpkgs.ghcid ]; })
else
  drv
