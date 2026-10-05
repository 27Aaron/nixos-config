{ ... }:
{
  programs.firefox.enable = true;

  persist'.directories = [
    ".config/mozilla"
    ".mozilla"
  ];
}
