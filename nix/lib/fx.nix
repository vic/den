{
  inputs,
  lib,
  ...
}:
let
  COMMENT = ''
  This is a prove of concept on using algebraic effects with handlers to make an 
  alternative-universe Den.

  In our current universe, Den has an informal half-baked manually-threaded effects system.

  # Den's context-passing

  It is not visible to most people, but we manually check for arg presence `host`,`user` and
  have to preserve those down the chain using recursive fixedTo.

  This in effects is basically the reader-monad: A computation requests a `host` from its
  computation environment, likewise requests a `user`, no matter how deeply nested the
  computation is, it can ask the computation environment (handlers) for needed stuff.

  This request<->response (from effectful-computations to effect-handlers) is the base of
  algebraic effect handlers.

  Den currently threads its environment (context in Den parlance) `{ host, user }` 
  explicitly, and we had some hard to find / fix bugs due to we manually doing it
  (or forgetting to do it).

  Also, Den currently uses functionArgs on aspects to determine context shapes.
  These shapes are not flexible since they are derived from what functions args are.
  They have defined shapes, eg, `{ a, b }` is a fixed context shape, if you wanted to
  introduce also `c`, we currently need another context shape `{ a, b, c }`.

  With bind.fn (feat at nix-effects#12) each of these function arguments are 
  independent requests to the environment, and any computation can choose to 
  requiest for `{ c }` or `{ a, c }` or `{ c, b }` and there's no need to thread them manually,
  no need for different context-shapes for every possible combination.

  With effects, each den.ctx stages becomes an scoped-effect-handler. (feat at nix-effects#8).
  Any given sub-computation (eg the part specific to a single user -- or the part specific to wsl) 
  can install effect handlers only as part of that sub-computation. This way effects can request
  "give me the current user I'm configuring" and they will see different values for each user.



  '';

  nix-effects = builtins.fetchTarball {
    url = "https://github.com/vic/nix-effects/archive/8004fefb7487fe5e88728f56ce487763588ecc34.zip";
    sha256 = "sha256:0bx7mmprh2gra4nzfbacl66cf1ypljqvwwj80gypci24bgzkmrnz";
  };

  fx = inputs.nix-effects.lib or (import nix-effects { inherit lib; });

in
fx //
{
}
