lib:
let

  resolve =
    step:
    let
      provided =
        if lib.isFunction step.aspect then
          step.aspect { inherit (step) class aspect-chain; }
        else
          step.aspect;

      module = provided.${step.class} or { };
      nextChain = step.aspect-chain ++ [ provided ];
      includes = provided.includes or [ ];
      nextStep =
        aspect:
        resolve {
          inherit (step) class;
          inherit aspect;
          aspect-chain = nextChain ++ [ aspect ];
          result = [ ];
        };

      result = step.result ++ (lib.optional (module != { }) module) ++ (lib.concatMap nextStep includes);
    in
    result;

in
class: aspect: {
  imports = resolve {
    inherit class aspect;
    aspect-chain = [ aspect ];
    result = [ ];
  };
}
