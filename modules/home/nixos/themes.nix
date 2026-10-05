{ pkgs, ... }:
{
  # nixpkgs has no Rosé Pine GTK theme (rose-pine-gtk-theme was dropped with
  # gtk-engine-murrine), so GTK uses adw-gtk3 while the icons and Qt theme
  # carry the Rosé Pine palette. The names are the directories the packages
  # install into share/themes and share/icons.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "kvantum";

    kvantum = {
      enable = true;
      settings.General.theme = "rose-pine-iris";
    };
  };

  # rose-pine-kvantum installs into share/Kvantum/themes, a directory Kvantum
  # does not scan, so link the theme straight into its config directory.
  xdg.configFile."Kvantum/rose-pine-iris".source =
    "${pkgs.rose-pine-kvantum}/share/Kvantum/themes/rose-pine-iris";

  gtk = {
    enable = true;

    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };

    gtk4.theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };

    iconTheme = {
      package = pkgs.rose-pine-icon-theme;
      name = "rose-pine";
    };

    font = {
      package = pkgs.cantarell-fonts;
      name = "Cantarell Regular";
      size = 12;
    };
  };

  # Libadwaita applications follow this rather than the GTK theme above.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  # State read and written through the managed GTK setup above.
  persist'.directories = [
    {
      directory = ".config/gtk-3.0";
      mode = "0700";
    }
    {
      directory = ".config/dconf";
      mode = "0700";
    }
  ];
}
