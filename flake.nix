{
  # WARNING this is very much still experimental.
  description = "A collection of darwin modules";

  outputs = { self, nixpkgs }: {
    lib = {
      evalConfig = import ./eval-config.nix;

      darwinSystem = args@{ modules, ... }: self.lib.evalConfig (
        { inherit (nixpkgs) lib; }
        // nixpkgs.lib.optionalAttrs (args ? pkgs) { inherit (args.pkgs) lib; }
        // builtins.removeAttrs args [ "system" "pkgs" "inputs" ]
        // {
          modules = modules
            ++ nixpkgs.lib.optional (args ? pkgs) ({ lib, ... }: {
              _module.args.pkgs = lib.mkForce args.pkgs;
            })
            # Backwards compatibility shim; TODO: warn?
            ++ nixpkgs.lib.optional (args ? system) ({ lib, ... }: {
              nixpkgs.system = lib.mkDefault args.system;
            })
            # Backwards compatibility shim; TODO: warn?
            ++ nixpkgs.lib.optional (args ? inputs) {
              _module.args.inputs = args.inputs;
            }
            ++ [ ({ lib, ... }: {
              nixpkgs.source = lib.mkDefault nixpkgs;

              system.checks.verifyNixPath = lib.mkDefault false;

              system.darwinVersionSuffix = ".${self.shortRev or "dirty"}";
              system.darwinRevision = lib.mkIf (self ? rev) self.rev;
            }) ];
          });
    };

    darwinModules.hydra = ./modules/examples/hydra.nix;
    darwinModules.lnl = ./modules/examples/lnl.nix;
    darwinModules.ofborg = ./modules/examples/ofborg.nix;
    darwinModules.simple = ./modules/examples/simple.nix;

    templates.default = {
      path = ./modules/examples/flake;
      description = "nix flake init -t nix-darwin";
    };

    checks = nixpkgs.lib.genAttrs ["aarch64-darwin" "x86_64-darwin"] (system: let
      simple = self.lib.darwinSystem {
        modules = [
          self.darwinModules.simple
          { nixpkgs.hostPlatform = system; }
        ];
      };
    in {
      simple = simple.system;

      inherit (simple.config.system.build.manual)
        optionsJSON
        manualHTML
        manpages;
    });
  };
}
