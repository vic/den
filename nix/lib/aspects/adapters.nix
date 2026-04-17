# Legacy pipeline only — GOF adapters for resolve.withAdapter.
# The fx pipeline uses meta.handleWith + constraint handlers instead.
# Remove when the legacy pipeline is removed.
#
# Adapters determine the return value of resolve. They are called for each
# resolved aspect and can recurse into includes, filter, or transform them.
#
# See resolve.nix for the arguments passed to adapters:
#   { aspect, class, classModule, recurse, aspect-chain, resolveChild }
{ den, lib, ... }:
let

  # Produces a single module importing all classModules from aspect and its includes.
  module =
    {
      classModule,
      recurse,
      aspect,
      ...
    }:
    {
      imports = classModule ++ lib.concatMap (i: (recurse i).imports or [ ]) (aspect.includes or [ ]);
    };

  # Conditionally apply adapter. Returns { } when pred fails (signals exclusion).
  filter =
    pred: adapter: args:
    if pred args.aspect then adapter args else { };

  # Post-process adapter result.
  map =
    f: adapter: args:
    f (adapter args);

  # Transform the aspect before passing to inner adapter.
  mapAspect =
    f: adapter: args:
    adapter (args // { aspect = f args.aspect; });

  # Transform includes before recursion.
  mapIncludes =
    f: adapter: args:
    adapter (args // { recurse = i: args.recurse (f i); });

  # Derive an aspect's identity path from name and provider.
  # Use instead of reference equality — resolved aspects are fresh attrsets.
  aspectPath = a: (a.meta.provider or [ ]) ++ [ (a.name or "<anon>") ];

  # Exclude by aspect reference. Also excludes aspects provided by the
  # reference (e.g., excluding monitoring also excludes monitoring.provides.node-exporter).
  excludeAspect =
    ref:
    let
      refPath = aspectPath ref;
    in
    filter (
      a:
      let
        ap = aspectPath a;
      in
      ap != refPath && lib.take (builtins.length refPath) ap != refPath
    );

  # Substitute an aspect reference with a replacement.
  substituteAspect =
    ref: replacement: mapAspect (a: if aspectPath a == aspectPath ref then replacement else a);

  # Empty aspect marking an excluded include. ~prefix prevents accidental
  # name collisions with live aspects. Harmless to module, visible to trace.
  # Consumers should check meta.excluded before accessing other aspect fields.
  # Tombstone fields:
  #   meta.excluded     — true
  #   meta.originalName — display name before ~prefix
  #   meta.provider     — who defines this aspect (structural origin, from provides chain)
  #   meta.excludedFrom — the parent aspect whose meta.adapter caused the exclusion
  #   meta.replacedBy   — name of the replacement (for substitutions only)
  tombstone =
    resolved: extra:
    let
      n = resolved.name or "<anon>";
    in
    {
      name = "~${n}";
      meta =
        (resolved.meta or { })
        // {
          excluded = true;
          originalName = n;
        }
        // extra;
    };

  # Extract what a metaAdapter transforms an aspect to (for substitution detection).
  # Assumes metaAdapter eventually calls its inner adapter exactly once.
  probeTransform =
    metaAdapter: args: resolved:
    (metaAdapter (_: { _probed = _.aspect; }) (args // { aspect = resolved; }))._probed or resolved;

  # Handles per-aspect meta.adapter composition. Probes each include to
  # determine: keep, exclude (tombstone), or substitute (tombstone + replacement).
  # Tags survivors with the adapter for downstream propagation.
  #
  # adapterOwner tracks which user-declared aspect originally owned the
  # adapter. Without it, tombstones downstream of a tagged wrapper
  # attribute exclusion to "<anon>" instead of the declaring aspect.
  filterIncludes =
    inner:
    args@{ aspect, resolveChild, ... }:
    let
      rawAdapter = aspect.meta.adapter or null;
      # Only process function adapters (legacy). Resolution handlers
      # (meta.handleWith) are handled by the fx pipeline separately.
      metaAdapter = if rawAdapter != null && lib.isFunction rawAdapter then rawAdapter else null;
      ownerName = aspect.meta.adapterOwner or (pathKey (aspectPath aspect));
    in
    if metaAdapter != null && aspect ? includes then
      let
        composed = metaAdapter (filterIncludes inner);

        processInclude =
          i:
          let
            resolved = resolveChild i;
            result = composed (
              args
              // {
                aspect = resolved;
                classModule = [ ];
              }
            );
            probed = probeTransform metaAdapter args resolved;
          in
          if result == { } then
            [ (tombstone resolved { excludedFrom = ownerName; }) ]
          else if aspectPath probed != aspectPath resolved then
            [
              (tombstone resolved {
                excludedFrom = ownerName;
                replacedBy = probed.name or "<anon>";
              })
              probed
            ]
          else
            [ i ];

        tag =
          i:
          if builtins.isAttrs i && i.meta.adapter or null == null && !(i.meta.excluded or false) then
            i
            // {
              meta = (i.meta or { }) // {
                adapter = metaAdapter;
                adapterOwner = ownerName;
              };
            }
          else
            i;
      in
      inner (
        args
        // {
          aspect = aspect // {
            includes = builtins.map tag (lib.concatMap processInclude aspect.includes);
          };
        }
      )
    else
      inner args;

  default = filterIncludes module;

  # Slash-joined key for an aspectPath. Canonical format for path
  # lookup sets.
  pathKey = path: lib.concatStringsSep "/" path;

  # Convert a list of aspectPaths into an attrset-as-set keyed by pathKey.
  toPathSet =
    paths:
    builtins.listToAttrs (
      builtins.map (p: {
        name = pathKey p;
        value = true;
      }) paths
    );

  # Emit this aspect's path if not excluded. Shared by collectPathsInner
  # and structuredTrace to avoid duplicating the exclusion check.
  collectSelfPath = aspect: lib.optional (!(aspect.meta.excluded or false)) (aspectPath aspect);

  # Shared walker used by collectPaths (through filterIncludes, so it
  # sees tombstones) and by oneOfAspects (raw, to avoid re-entering
  # its own meta.adapter). The excluded-guard is a no-op in the raw
  # use since tombstones only appear after filterIncludes runs.
  collectPathsInner =
    { aspect, recurse, ... }:
    {
      paths =
        collectSelfPath aspect ++ lib.concatMap (i: (recurse i).paths or [ ]) (aspect.includes or [ ]);
    };

  # Terminal adapter that walks via filterIncludes and collects the
  # aspectPath of every non-tombstone aspect. Result shape:
  # { paths = [ [providerSeg..., name], ... ]; }. Depth-first, not deduped.
  collectPaths = filterIncludes collectPathsInner;

  # meta.adapter that keeps the first candidate structurally present
  # in the parent subtree and tombstones the rest via excludeAspect.
  #
  #   meta.adapter = oneOfAspects [ <agenix-rekey> <sops-nix> ];
  #
  # No-op when no candidates are present. Presence is determined
  # from the raw tree (bypassing filterIncludes) so we don't re-enter
  # our own meta.adapter.
  oneOfAspects =
    candidates: inherited:
    args@{ class, aspect-chain, ... }:
    let
      # filterIncludes rebinds args.aspect to each child but keeps
      # aspect-chain, whose tail is still the parent that owns us.
      parent = lib.last aspect-chain;
      subtree = den.lib.aspects.resolve.withAdapter collectPathsInner class parent;
      present-keys = toPathSet (subtree.paths or [ ]);
      keyOf = c: pathKey (aspectPath c);
      present = builtins.filter (c: present-keys ? ${keyOf c}) candidates;
      losers = if present == [ ] then [ ] else builtins.tail present;
    in
    (lib.foldl' (inner: loser: excludeAspect loser inner) inherited losers) args;

  # Traces aspect.name as nested lists per includes. Composed with filterIncludes
  # so tombstones and substitutions are visible.
  #
  # trace.on takes a function to extract any value from aspect.
  trace = {
    __functor = _: trace.on (a: a.name or "<anon>");
    on =
      f:
      filterIncludes (
        { aspect, recurse, ... }:
        {
          trace = [ (f aspect) ] ++ builtins.map (i: (recurse i).trace or [ ]) (aspect.includes or [ ]);
        }
      );
  };

  # Structured trace producing flat entry lists with rich metadata.
  # Each entry carries name, class, parent path, provider chain,
  # exclusion info, parametric detection, and context stage tags.
  # Returns { trace = [entries]; paths = [aspectPaths]; }.
  structuredTrace = filterIncludes (
    {
      aspect,
      recurse,
      class,
      classModule,
      aspect-chain,
      ...
    }:
    let
      meaningful =
        name: name != "<anon>" && name != "<function body>" && !(lib.hasPrefix "[definition " name);
      rawName = aspect.meta.originalName or aspect.name or "<anon>";
      depth = builtins.length aspect-chain;
      provPath = lib.concatStringsSep "/" (aspect.meta.provider or [ ]);
      ctxStages' = builtins.filter (a: builtins.isAttrs a && a ? __ctxStage) aspect-chain;
      nearestCtx = if ctxStages' == [ ] then null else lib.last ctxStages';
      ctxKind' = if nearestCtx != null then nearestCtx.__ctxKind or null else null;
      ctxStage' = if nearestCtx != null then nearestCtx.__ctxStage or null else null;
      ctxAspect' = if nearestCtx != null then nearestCtx.__ctxAspect or null else null;
      name =
        if rawName == "<anon>" || rawName == "<function body>" || lib.hasPrefix "[definition " rawName then
          let
            stage = if ctxStage' != null then ctxStage' else "d${toString depth}";
            kind = if ctxKind' != null then ctxKind' else "resolve";
            aspectTag = if ctxAspect' != null then "(${ctxAspect'})" else "";
            provTag = lib.optionalString (provPath != "") ":${provPath}";
          in
          "${stage}/${kind}${aspectTag}${provTag}"
        else
          rawName;
      selfFullPath = if provPath != "" then "${provPath}/${name}" else name;
      chainBareName = a: a.meta.originalName or a.name or "<anon>";
      chainFullPath =
        a:
        let
          bare = chainBareName a;
          prov = a.meta.provider or [ ];
        in
        if prov != [ ] then lib.concatStringsSep "/" (prov ++ [ bare ]) else bare;
      parentPaths = builtins.filter (
        fp: fp != selfFullPath && meaningful (lib.last (lib.splitString "/" fp))
      ) (builtins.map chainFullPath aspect-chain);
      chainLen = builtins.length aspect-chain;
      rawProvided = if chainLen >= 2 then builtins.elemAt aspect-chain (chainLen - 2) else null;
      rawFnArgs =
        if
          rawProvided != null
          && (builtins.isFunction rawProvided || (builtins.isAttrs rawProvided && rawProvided ? __functor))
        then
          lib.functionArgs rawProvided
        else
          { };
      entry = {
        inherit name class;
        isParametric = rawFnArgs != { };
        fnArgNames = builtins.attrNames rawFnArgs;
        hasClass = classModule != [ ];
        parent = if parentPaths == [ ] then null else lib.last parentPaths;
        provider = aspect.meta.provider or [ ];
        excluded = aspect.meta.excluded or false;
        excludedFrom = aspect.meta.excludedFrom or null;
        replacedBy = aspect.meta.replacedBy or null;
        isProvider = (aspect.meta.provider or [ ]) != [ ];
        hasAdapter = aspect.meta.adapter or null != null;
        ctxStage = if nearestCtx != null then nearestCtx.__ctxStage else null;
        ctxKind = if nearestCtx != null then nearestCtx.__ctxKind else null;
      };
      childResults = builtins.map recurse (aspect.includes or [ ]);
      childTraces = lib.concatMap (r: r.trace or [ ]) childResults;
      childPaths = lib.concatMap (r: r.paths or [ ]) childResults;
    in
    {
      trace = [ entry ] ++ childTraces;
      paths = collectSelfPath aspect ++ childPaths;
    }
  );

in
{
  inherit
    aspectPath
    collectPaths
    collectSelfPath
    default
    excludeAspect
    filter
    filterIncludes
    map
    mapAspect
    mapIncludes
    module
    oneOfAspects
    pathKey
    structuredTrace
    substituteAspect
    toPathSet
    tombstone
    trace
    ;
}
