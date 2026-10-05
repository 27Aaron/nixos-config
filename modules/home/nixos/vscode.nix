{ ... }:
{
  programs.vscode.enable = true;

  persist'.directories = [
    ".config/Code"
    ".vscode"
  ];
}
