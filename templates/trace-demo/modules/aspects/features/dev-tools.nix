{ den, ... }:
{
  den.aspects.dev-tools.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ripgrep
        fd
        jq
      ];
    };
}
