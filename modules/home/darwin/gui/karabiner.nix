{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gui.karabiner;

  generatedConfig = builtins.toFile "karabiner.json" (
    builtins.toJSON {
      profiles = [
        {
          complex_modifications = {
            rules = [
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
                    to_if_alone = [
                      {
                        key_code = "f19";
                      }
                    ];
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
                    to = [
                      {
                        key_code = "left_control";
                      }
                    ];
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
          };
          # 接上這把外接鍵盤時停用內建鍵盤。
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
          name = "Default profile";
          selected = true;
          virtual_hid_keyboard = {
            keyboard_type_v2 = "ansi";
          };
        }
      ];
    }
  );
in
{
  # Karabiner-Elements 本身由 programs'.homebrew 的 cask 安裝,這裡只管設定檔。
  options.gui.karabiner.enable = lib.mkEnableOption "the Karabiner-Elements configuration";

  config = lib.mkIf cfg.enable {
    # Karabiner 的 GUI 會改寫設定檔,唯讀的 store 連結會讓它無法儲存;
    # 因此每次啟用時改為安裝一份可寫入的副本。
    home.activation.initializeKarabiner =
      lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
        ''
          (
            set -eu
            export PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"
            dir=${lib.escapeShellArg "${config.xdg.configHome}/karabiner"}
            gen=${lib.escapeShellArg generatedConfig}

            if [[ -v DRY_RUN ]]; then
              echo "Would install editable Karabiner configuration in $dir"
              exit 0
            fi
            if [[ -L "$dir" ]]; then
              echo "Replace the Karabiner directory link with a regular directory first: $dir" >&2
              exit 1
            fi

            umask 077
            mkdir -p -- "$dir"
            tmp="$dir/.karabiner.json.tmp"
            install -m 600 -- "$gen" "$tmp"
            mv -fT -- "$tmp" "$dir/karabiner.json"
          )
        '';
  };
}
