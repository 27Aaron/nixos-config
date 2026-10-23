{
  config,
  inputs,
  vars,
  ...
}:
{
  imports = [ inputs.sops-nix.darwinModules.sops ];

  sops.age.sshKeyPaths = [ "${config.users.users.${vars.username}.home}/.ssh/id_ed25519" ];
}
