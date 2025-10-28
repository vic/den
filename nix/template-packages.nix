let
  rev = "9100a0f";
  narHash = "sha256:09m84vsz1py50giyfpx0fpc7a4i0r1xsb54dh0dpdg308lp4p188";
  compat = fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/${rev}.tar.gz";
    sha256 = narHash;
  };
  flake = import compat { src = ../templates/default; };
  pkgs = flake.outputs.packages;
in
{
  x86_64-linux.default = pkgs.x86_64-linux.vm;
}
