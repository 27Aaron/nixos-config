# Named role compositions. Each entry is a list of modules, and entries may
# extend each other, so a host only has to name the roles it plays.
{
  nixos = import ./nixos;
  darwin = import ./darwin;
  home = import ./home;
}
