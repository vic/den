{ lib, ... }:
elemType:
lib.types.mkOptionType {
  name = "lastFunctionTo";
  description = "last function to ${elemType.description}";
  check = (lib.types.functionTo elemType).check;
  merge = _loc: defs: (lib.last defs).value;
}
