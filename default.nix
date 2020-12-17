/*

1) Build and test all of the packages in the project: This will build the
`liquidhaskell_test-runner-metapackage`, which depends on everything else and
builds & tests the `liquidhaskell` package.

    nix-build --no-out-link

2) Enter an environment suitable for development & testing of the
`liquidhaskell` package: This is the deveoplment environment of the
`liquidhaskell_test-runner-metapackage`. All of the other packages are
installed in this environment, including an un-tested instance of the
`liquidhaskell` package.

    nix-shell

3) Build and test one package in the project: This will build and test only the
named package. You could name anything in haskellPackages but only components
of liquid haskell have their tests enabled. Don't use this for the
`liquidhaskell` project, for that use #1.

    nix-build --argstr target liquid-vector

4) enter an environment suitable for development & testing of one package in
the project: You could name anything in haskellPackages. Don't use this for the
`liquidhaskell` package itself because you wont have the rest of the project
available and so its tests wont run, for that use #2 above.

    nix-shell --argstr target liquid-vector

*/
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
  nixpkgs = import
    (builtins.fetchTarball {
      # fetch latest nixpkgs https://github.com/NixOS/nixpkgs/commits/nixos-20.03 as of Thu 17 Dec 2020 09:16:47 PM UTC
      url = "https://github.com/NixOS/nixpkgs/archive/030e2ce817c8e83824fb897843ff70a15c131b96.tar.gz";
      sha256 = "110kgp4x5bx44rgw55ngyhayr4s19xwy19n6qw9g01hvhdisilwf";
    })
    { inherit config; };
  # helper to turn on tests, haddocks, and have z3 around
  beComponent = pkg: another: nixpkgs.haskell.lib.overrideCabal pkg (
    old:
    { doCheck = tests; doHaddock = true; buildTools = old.buildTools or [ ] ++ [ nixpkgs.z3 ]; }
    // another old
  );
  # package set for haskell compiler version
  haskellCompilerPackages = nixpkgs.haskell.packages."ghc8101";
  # override package set to inject project components
  haskellPackages = haskellCompilerPackages.override (
    old: {
      all-cabal-hashes = nixpkgs.fetchurl {
        # fetch latest cabal hashes https://github.com/commercialhaskell/all-cabal-hashes/tree/hackage as of Thu 17 Dec 2020 09:17:17 PM UTC
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/b195164429272e5bc9da2459e5094e94c8ede3b3.tar.gz";
        sha256 = "07j6l7ppmvgcylyb2pgv6zwa7sx2x25sz7pj94cjfb0h9673nirq";
      };
      overrides = self: super: with nixpkgs.haskell.lib; rec {
        # turn off tests and haddocks and version bounds by default
        mkDerivation = args: super.mkDerivation (
          args // { doCheck = false; doHaddock = false; jailbreak = true; }
        );
        # declare each of the packages contained in this repo
        ## LH support packages
        liquidhaskell = self.callCabal2nix "liquidhaskell" (nixpkgs.nix-gitignore.gitignoreSource [ ] ./.) { }; # no tests are run; we define a separate package below to run the tests
        liquid-fixpoint = beComponent (self.callCabal2nix "liquid-fixpoint" (nixpkgs.nix-gitignore.gitignoreSource [ ] ./liquid-fixpoint) { })
          (old: { preCheck = ''export PATH="$PWD/dist/build/fixpoint:$PATH"''; }); # bring the `fixpoint` binary into scope for tests run by nix-build
        ## LH spec packages
        liquid-base = beComponent (self.callCabal2nix "liquid-base" ./liquid-base { }) (_: { doHaddock = false; });
        liquid-bytestring = beComponent (self.callCabal2nix "liquid-bytestring" ./liquid-bytestring { }) (_: { doHaddock = false; });
        liquid-containers = beComponent (self.callCabal2nix "liquid-containers" ./liquid-containers { }) (_: { });
        liquid-ghc-prim = beComponent (self.callCabal2nix "liquid-ghc-prim" ./liquid-ghc-prim { }) (_: { doHaddock = false; });
        liquid-parallel = beComponent (self.callCabal2nix "liquid-parallel" ./liquid-parallel { }) (_: { });
        liquid-vector = beComponent (self.callCabal2nix "liquid-vector" ./liquid-vector { }) (_: { });
        ## LH bundles
        liquid-platform = beComponent (self.callCabal2nix "liquid-platform" ./liquid-platform { }) (_: { });
        liquid-prelude = beComponent (self.callCabal2nix "liquid-prelude" ./liquid-prelude { }) (_: { doHaddock = false; });
        # dependencies
        ## declare dependencies using the latest hackage releases as of Fri 11 Sep 2020 05:48:57 AM UTC
        th-compat = self.callHackage "th-compat" "0.1" { };
        hashable = self.callHackage "hashable" "1.3.0.0" { }; # ouch; requires recompilation of around 30 packages
        optics = self.callHackage "optics" "0.3" { };
        optics-core = self.callHackage "optics-core" "0.3.0.1" { };
        optics-extra = self.callHackage "optics-extra" "0.3" { };
        optics-th = self.callHackage "optics-th" "0.3.0.2" { };
        megaparsec = self.callHackage "megaparsec" "9.0.1" { };
        ## declare test-dependencies using the latest hackage releases as of Thu 27 Aug 2020 04:08:52 PM UTC
        memory = self.callHackage "memory" "0.15.0" { };
        git = overrideCabal (self.callHackage "git" "0.3.0" { }) (
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
            testDepends = old.testDepends or [ ] ++ [ nixpkgs.hostname ];
            testHaskellDepends = old.testHaskellDepends ++ projectPackages;
            preCheck = ''export TASTY_LIQUID_RUNNER="liquidhaskell -v0"'';
            passthru = { inherit nixpkgs;inherit haskellPackages;inherit projectPackages; };
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
