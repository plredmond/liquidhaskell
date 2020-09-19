{
  # Set `mkEnv` to choose whether to return a package or a development
  # environment. The default is to follow inNixShell.
  mkEnv ? null
, # Set `tests` to choose whether to run the test suites in liquid haskell
  # packages.
  tests ? true
, # Set `target` to choose the package from haskellPackages which will be
  # returned (eg. name of a liquidhaskell package).
  target ? "liquidhaskell_test-runner-metapackage"
, # nixpkgs config
  config ? { allowBroken = true; }
}:
let
  nixpkgs = import (
    builtins.fetchTarball {
      # fetch latest nixpkgs https://github.com/NixOS/nixpkgs-channels/tree/nixos-20.03 as of Fri 18 Sep 2020 11:07:29 PM UTC
      url = "https://github.com/NixOS/nixpkgs-channels/archive/faf5bdea5d9f0f9de26deaa7e864cdcd3b15b4e8.tar.gz";
      sha256 = "1sgfyxi4wckivnbniwmg4l6n9v5z6v53c5467d7k7pr2h6nwssfn";
    }
  ) { inherit config; };
  # helper to turn on tests, haddocks, and have z3 around
  beComponent = pkg: another: nixpkgs.haskell.lib.overrideCabal pkg (
    old:
      { doCheck = tests; doHaddock = true; buildTools = old.buildTools or [] ++ [ nixpkgs.z3 ]; }
      // another old
  );
  # package set for haskell compiler version
  haskellCompilerPackages = nixpkgs.haskell.packages."ghc8101";
  # override package set to inject project components
  haskellPackages = haskellCompilerPackages.override (
    old: {
      all-cabal-hashes = nixpkgs.fetchurl {
        # fetch latest cabal hashes https://github.com/commercialhaskell/all-cabal-hashes/tree/hackage as of Fri 18 Sep 2020 11:08:25 PM UTC
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/95c936f1dad30718d4fd37673fe5ee204c60a442.tar.gz";
        sha256 = "1z9zfa8z06w6ks54z3a2afrrg3mzpi3xik617x9nkkdl0vvn2riz";
      };
      overrides = self: super: with nixpkgs.haskell.lib; rec {
        # turn off tests and haddocks and version bounds by default
        mkDerivation = args: super.mkDerivation (
          args // { doCheck = false; doHaddock = false; jailbreak = true; }
        );
        # declare each of the liquid-haskell packages using the latest hackage releases as of Fri 18 Sep 2020 11:17:35 PM UTC
        ## LH support packages
        liquidhaskell = self.callHackage "liquidhaskell" "0.8.10.2" {};
        liquid-fixpoint = self.callHackage "liquid-fixpoint" "0.8.10.2" {};
        ## LH spec packages
        liquid-base = beComponent (self.callHackage "liquid-base" "4.14.1.0" {}) (_: { doHaddock = false; });
        liquid-bytestring = beComponent (self.callHackage "liquid-bytestring" "0.10.10.0" {}) (_: { doHaddock = false; });
        liquid-containers = beComponent (self.callHackage "liquid-containers" "0.6.2.1" {}) (_: {});
        liquid-ghc-prim = beComponent (self.callHackage "liquid-ghc-prim" "0.6.1" {}) (_: { doHaddock = false; });
        liquid-parallel = beComponent (self.callHackage "liquid-parallel" "3.2.2.0" {}) (_: {});
        liquid-vector = beComponent (self.callHackage "liquid-vector" "0.12.1.2" {}) (_: {});
        ## LH bundles
        liquid-platform = beComponent (self.callHackage "liquid-platform" "0.8.10.2" {}) (_: {});
        liquid-prelude = beComponent (self.callHackage "liquid-prelude" "0.8.10.2" {}) (_: { doHaddock = false; });
        # dependencies
        ## declare dependencies using the latest hackage releases as of Fri 18 Sep 2020 11:18:16 PM UTC
        hashable = self.callHackage "hashable" "1.3.0.0" {}; # ouch; requires recompilation of around 30 packages
        optics = self.callHackage "optics" "0.3" {};
        optics-core = self.callHackage "optics-core" "0.3.0.1" {};
        optics-extra = self.callHackage "optics-extra" "0.3" {};
        optics-th = self.callHackage "optics-th" "0.3.0.2" {};
        ## declare test-dependencies using the latest hackage releases as of Thu 27 Aug 2020 04:08:52 PM UTC
        memory = self.callHackage "memory" "0.15.0" {};
        git = overrideCabal (self.callHackage "git" "0.3.0" {}) (
          old: {
            patches = [
              (
                nixpkgs.writeText "git-0.3.0_fix-monad-fail-for-ghc-8.10.1.patch" ''
                  diff --git a/Data/Git/Monad.hs b/Data/Git/Monad.hs
                  index 480af9f..27c3b3e 100644
                  --- a/Data/Git/Monad.hs
                  +++ b/Data/Git/Monad.hs
                  @@ -130 +130 @@ instance Resolvable Git.RefName where
                  -class (Functor m, Applicative m, Monad m) => GitMonad m where
                  +class (Functor m, Applicative m, Monad m, MonadFail m) => GitMonad m where
                  @@ -242,0 +243 @@ instance Monad GitM where
                  +instance MonadFail GitM where
                  @@ -315,0 +317 @@ instance Monad CommitAccessM where
                  +instance MonadFail CommitAccessM where
                  @@ -476,0 +479 @@ instance Monad CommitM where
                  +instance MonadFail CommitM where
                ''
              )
            ];
          }
        );
        # declare a duplicate liquidhaskell package that depends on the above so that we can run its tests
        liquidhaskell_test-runner-metapackage = beComponent liquidhaskell (
          old: {
            testDepends = old.testDepends or [] ++ [ nixpkgs.hostname ];
            testHaskellDepends = old.testHaskellDepends ++ projectPackages;
            preCheck = ''export TASTY_LIQUID_RUNNER="liquidhaskell -v0"'';
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

    liquid-base
    liquid-bytestring
    liquid-containers
    liquid-ghc-prim
    liquid-parallel
    liquid-vector

    liquid-platform
    liquid-prelude
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
