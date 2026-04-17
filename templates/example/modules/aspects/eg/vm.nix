{ eg, ... }:
{
  eg.vm.provides = {
    gui.includes = [
      eg.vm
      eg.vm-bootable.provides.gui
      eg.xfce-desktop
    ];

    tui.includes = [
      eg.vm
      eg.vm-bootable.provides.tui
    ];
  };
}
