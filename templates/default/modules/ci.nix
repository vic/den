{ config, ... }:
{

  den.default.includes = [

    # USER TODO: Remove.
    (
      # This is a conditional aspect to disable boot during CI on all hosts.
      if config ? _module.args.CI then
        {
          nixos.fileSystems."/".device = "/dev/fake";
          nixos.boot.loader.grub.enable = false;
        }
      else
        { }
    )

  ];

}
