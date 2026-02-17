{ inputs, lib, ... }:
if inputs ? flake-parts then
  { }
else
  {
    # NOTE: Currently Den needs a top-level attribute where to place configurations,
    # by default it is the `flake` attribute, even if Den uses no flake-parts at all.

    # This definitions has been adapted from https://github.com/hercules-ci/flake-parts
    # project which is licensed with:
    #
    # MIT License
    #
    # Copyright (c) 2021 Hercules CI
    #
    # Permission is hereby granted, free of charge, to any person obtaining a copy
    # of this software and associated documentation files (the "Software"), to deal
    # in the Software without restriction, including without limitation the rights
    # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    # copies of the Software, and to permit persons to whom the Software is
    # furnished to do so, subject to the following conditions:
    #
    # The above copyright notice and this permission notice shall be included in all
    # copies or substantial portions of the Software.
    #
    # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    # SOFTWARE.
    options.flake = lib.mkOption {
      type = lib.types.submoduleWith {
        modules = [
          {
            freeformType = lib.types.lazyAttrsOf (
              lib.types.unique {
                message = ''
                  No option has been declared for this flake output attribute, so its definitions can't be merged automatically.
                  Possible solutions:
                    - Load a module that defines this flake output attribute
                    - Declare an option for this flake output attribute
                    - Make sure the output attribute is spelled correctly
                    - Define the value only once, with a single definition in a single module
                '';
              } lib.types.raw
            );
          }
        ];
      };
    };
  }
