# "Just Give 'Em One of These" -  Moe Szyslak
# A __functor that applies context to parametric includes (functions)
{ lib, ... }:
apply: aspect:
aspect
// {
  __functor = self: ctx: {
    includes = builtins.filter (x: x != { }) (
      map (apply ctx) (builtins.filter lib.isFunction (self.includes or [ ]))
    );
  };
}
