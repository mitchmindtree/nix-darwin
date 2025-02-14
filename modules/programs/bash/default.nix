{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.bash;
in

{
  options = {

    programs.bash.enable = mkOption {
      type = types.bool;
      default = true;
      description = lib.mdDoc "Whether to configure bash as an interactive shell.";
    };

    programs.bash.interactiveShellInit = mkOption {
      default = "";
      description = lib.mdDoc "Shell script code called during interactive bash shell initialisation.";
      type = types.lines;
    };

    programs.bash.enableCompletion = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Enable bash completion for all interactive bash shells.

        NOTE. This doesn't work with bash 3.2, which is the default on macOS.
      '';
    };

  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      [ # Include bash package
        pkgs.bashInteractive
      ] ++ optional cfg.enableCompletion pkgs.bash-completion;

    environment.pathsToLink =
      [ "/etc/bash_completion.d"
        "/share/bash-completion/completions"
      ];

    environment.etc."bashrc".text = ''
      # /etc/bashrc: DO NOT EDIT -- this file has been generated automatically.
      # This file is read for interactive shells.

      [ -r "/etc/bashrc_$TERM_PROGRAM" ] && . "/etc/bashrc_$TERM_PROGRAM"

      # Only execute this file once per shell.
      if [ -n "$__ETC_BASHRC_SOURCED" -o -n "$NOSYSBASHRC" ]; then return; fi
      __ETC_BASHRC_SOURCED=1

      # Don't execute this file when running in a pure nix-shell.
      if test -n "$IN_NIX_SHELL"; then return; fi

      if [ -z "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" ]; then
        . ${config.system.build.setEnvironment}
      fi

      # Return early if not running interactively, but after basic nix setup.
      [[ $- != *i* ]] && return

      # Make bash check its window size after a process completes
      shopt -s checkwinsize

      ${config.system.build.setAliases.text}

      ${config.environment.interactiveShellInit}
      ${cfg.interactiveShellInit}

      ${optionalString cfg.enableCompletion ''
        if [ "$TERM" != "dumb" ]; then
          source "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"

          nullglobStatus=$(shopt -p nullglob)
          shopt -s nullglob
          for p in $NIX_PROFILES; do
            for m in "$p/etc/bash_completion.d/"*; do
              source $m
            done
          done
          eval "$nullglobStatus"
          unset nullglobStatus p m
        fi
      ''}

      # Read system-wide modifications.
      if test -f /etc/bash.local; then
        source /etc/bash.local
      fi
    '';

    environment.etc."bashrc".knownSha256Hashes = [
      "444c716ac2ccd9e1e3347858cb08a00d2ea38e8c12fdc5798380dc261e32e9ef"
      "617b39e36fa69270ddbee19ddc072497dbe7ead840cbd442d9f7c22924f116f4"  # nix installer
      "6be16cf7c24a3c6f7ae535c913347a3be39508b3426f5ecd413e636e21031e66"  # nix installer
    ];

  };
}
