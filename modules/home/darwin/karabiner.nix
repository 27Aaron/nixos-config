# Karabiner only reloads when ~/.config/karabiner is a real directory rather
# than a symlinked karabiner.json, so install a writable copy on activation.
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  enabled = lib.any (c: (c.name or c) == "karabiner-elements") osConfig.homebrew.casks;

  karabinerJson = builtins.toJSON {
    profiles = [
      {
        name = "Default profile";
        selected = true;

        virtual_hid_keyboard.keyboard_type_v2 = "ansi";

        complex_modifications.rules = [
          {
            description = "Change right_command key to command+control+option+shift. (Post f19 key when pressed alone)";
            manipulators = [
              {
                from = {
                  key_code = "right_command";
                  modifiers.optional = [ "any" ];
                };
                to = [
                  {
                    key_code = "left_shift";
                    modifiers = [
                      "left_command"
                      "left_control"
                      "left_option"
                    ];
                  }
                ];
                to_if_alone = [ { key_code = "f19"; } ];
                type = "basic";
              }
            ];
          }
          {
            description = "Click Control => Capslock , Long press Control => Control";
            manipulators = [
              {
                from = {
                  key_code = "left_control";
                  modifiers.optional = [ "any" ];
                };
                to = [ { key_code = "left_control"; } ];
                to_if_alone = [
                  {
                    hold_down_milliseconds = 100;
                    key_code = "caps_lock";
                  }
                ];
                type = "basic";
              }
            ];
          }
        ];

        devices = [
          {
            disable_built_in_keyboard_if_exists = true;
            identifiers = {
              is_keyboard = true;
              product_id = 33;
              vendor_id = 1278;
            };
          }
        ];
      }
    ];
  };
in
{
  config = lib.mkIf enabled {
    home.activation.installKarabiner =
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
        ''
          set -eu
          dir=${lib.escapeShellArg "${config.xdg.configHome}/karabiner"}
          export PATH=${lib.makeBinPath [ pkgs.coreutils ]}:$PATH

          mkdir -p "$dir"
          umask 077
          rm -f "$dir/karabiner.json"
          install -m 600 ${pkgs.writeText "karabiner.json" karabinerJson} "$dir/karabiner.json"
        '';
  };
}
