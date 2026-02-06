{ eg, ... }:
{
  eg.vm.provides = {
    gui.includes = [
      eg.vm
      eg.vm-bootable._.gui
      eg.xfce-desktop
    ];

    tui.includes = [
      eg.vm
      eg.vm-bootable._.tui
    ];
  };
}
