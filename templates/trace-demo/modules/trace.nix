# Mermaid trace visualization for aspect resolution.
#
# Host aspects use standard adapters (excludeAspect, substituteAspect, filter)
# via meta.adapter. filterIncludes produces tombstones automatically — the
# traceAdapter here collects structured entries for the Mermaid renderer.
{
  den,
  lib,
  self,
  ...
}:
let
  inherit (den.lib.aspects) adapters;

  # Context pipeline internals to filter from rendered output.
  contextNodes = [
    "host"
    "default"
    "hm-host"
    "hm-user"
    "user"
  ];

  # Resolve a host aspect for all classes using structuredTrace.
  traceHost = hostName: hostAspect:
    let
      classes = [ "nixos" "homeManager" ];
      traceFor = class:
        (den.lib.aspects.resolve.withAdapter adapters.structuredTrace class hostAspect).trace or [ ];
    in
    traceToMermaid hostName (lib.concatMap traceFor classes);

  # --- Mermaid renderer ---

  sanitize = lib.replaceStrings [ "-" " " "." "@" "/" "~" ] [ "_" "_" "_" "_" "_" "_" ];

  displayName = entry:
    if entry.provider != [ ] then
      lib.concatStringsSep "/" (entry.provider ++ [ entry.name ])
    else
      entry.name;

  isUserEntry = entry:
    let n = entry.name;
    in n != "<anon>" && n != "<function body>" && !(lib.hasPrefix "[definition " n)
      && lib.take 1 (entry.provider or [ ]) != [ "den" ]
      && !builtins.elem n contextNodes;

  dedupBy = keyFn: items:
    (builtins.foldl' (
      acc: item:
      let k = keyFn item;
      in
      if acc.seen ? ${k} then acc
      else { seen = acc.seen // { ${k} = true; }; result = acc.result ++ [ item ]; }
    ) { seen = { }; result = [ ]; } items).result;

  traceToMermaid = hostName: trace:
    let
      entries = builtins.filter isUserEntry trace;

      nodes = dedupBy displayName entries;

      # Reparent children of filtered context nodes to hostName.
      reparent = parent:
        if parent == null then null
        else if builtins.elem parent contextNodes then hostName
        else parent;

      edges = dedupBy (e: "${e.from}-->${e.to}:${e.class}") (
        builtins.concatMap (
          entry:
          let parent = reparent entry.parent;
          in
          if parent == null || parent == entry.name || entry.name == hostName then [ ]
          else [{ from = parent; to = entry.name; inherit (entry) class excluded excludedFrom replacedBy; }]
        ) entries
      );

      classes = lib.unique (map (e: e.class) edges);
      hasMultipleClasses = builtins.length classes > 1;

      edgeKey = e: "${e.from}-->${e.to}";
      allEdges = dedupBy (e: "${edgeKey e}:${e.class}") edges;

      # Drop tombstone edges from classes where their parent has no
      # non-tombstone edges. Prevents nixos-only excludes leaking into homeManager.
      parentsWithContent = cls:
        lib.listToAttrs (map (e: { name = e.from; value = true; })
          (builtins.filter (e: !e.excluded && e.class == cls) allEdges));
      classOnlyEdges = builtins.filter (e:
        !e.excluded || (parentsWithContent e.class) ? ${e.from}
      ) allEdges;

      # Node shapes:
      #   ([...])  host root (stadium)
      #   [/...\]  provider sub-aspect (trapezoid)
      #   [...]    default (rectangle)
      nodeDecl = entry:
        let
          id = sanitize entry.name;
          label = displayName entry;
          style =
            if entry.excluded && entry.replacedBy != null then ":::replaced"
            else if entry.excluded then ":::excluded"
            else "";
          shape =
            if entry.isProvider then "[/${label}\\]"
            else "[${label}]";
        in
        "  ${id}${shape}${style}";

      sortEdges = lib.sort (a: b: a.from < b.from || (a.from == b.from && a.to < b.to));

      edgeArrow = edge:
        if edge.excluded && edge.replacedBy != null then
          "-.->|replaced|"
        else if edge.excluded then
          "-.-x"
        else
          "-->";

      edgeDecl = edge:
        "  ${sanitize edge.from} ${edgeArrow edge} ${sanitize edge.to}";

      classEdgeDecl = cls: edge:
        let prefix = n: if n == hostName then sanitize n else "${sanitize cls}_${sanitize n}";
        in "  ${prefix edge.from} ${edgeArrow edge} ${prefix edge.to}";

      # Class-prefixed node declaration inside a subgraph.
      classNodeDecl = cls: entry:
        let
          id = "${sanitize cls}_${sanitize entry.name}";
          label = displayName entry;
          style =
            if entry.excluded && entry.replacedBy != null then ":::replaced"
            else if entry.excluded then ":::excluded"
            else "";
          shape =
            if entry.isProvider then "[/${label}\\]"
            else "[${label}]";
        in
        "  ${id}${shape}${style}";

      classSubgraph = cls:
        let
          clsEdges = sortEdges (builtins.filter (e: e.class == cls) classOnlyEdges);
          # Collect node names referenced by edges in this class.
          clsNodeNames = lib.unique (
            lib.concatMap (e: lib.optional (e.from != hostName) e.from ++ lib.optional (e.to != hostName) e.to) clsEdges
          );
          clsNodes = lib.sort (a: b: a.name < b.name) (
            builtins.filter (e: builtins.elem e.name clsNodeNames) nodes
          );
        in lib.optional (clsEdges != [ ]) (
          "  subgraph ${sanitize cls}[${cls}]\n"
          + lib.concatMapStringsSep "\n" (classNodeDecl cls) clsNodes
          + "\n"
          + lib.concatMapStringsSep "\n" (classEdgeDecl cls) clsEdges
          + "\n  end"
        );

      # Subgraph background colors (muted, works in light and dark mode).
      subgraphStyles = {
        nixos = "style nixos fill:transparent,stroke:#5b8db8,stroke-width:2px";
        homeManager = "style homeManager fill:transparent,stroke:#9b72b0,stroke-width:2px";
      };

      renderedClasses = builtins.filter (cls: builtins.filter (e: e.class == cls) classOnlyEdges != [ ]) classes;
    in
    lib.concatStringsSep "\n" (
      [ "graph TD" "  ${sanitize hostName}([${hostName}]):::host" ]
      ++ (if hasMultipleClasses then
        # Multi-class: nodes declared inside subgraphs with class-prefixed IDs.
        [ "" ] ++ lib.concatMap classSubgraph renderedClasses
      else
        # Single class: flat nodes and edges.
        map nodeDecl (lib.sort (a: b: a.name < b.name) (builtins.filter (e: e.name != hostName) nodes))
        ++ [ "" ]
        ++ map edgeDecl (sortEdges classOnlyEdges)
      )
      ++ [ ""
        "  classDef host fill:#3a8f6a,stroke:#2d7a5f,color:#fff,font-weight:bold"
        "  classDef excluded fill:#b05060,stroke:#903040,color:#fff,stroke-dasharray: 5 5"
        "  classDef replaced fill:#b08930,stroke:#907020,color:#fff,stroke-dasharray: 5 5"
      ]
      ++ lib.optionals hasMultipleClasses (map (cls: subgraphStyles.${cls} or "") renderedClasses)
    );

  # --- Host trace collection ---

  allHosts = lib.concatMap builtins.attrValues (builtins.attrValues den.hosts);

  allTraces = builtins.listToAttrs (map (host: {
    name = host.name;
    value = traceHost host.name (den.ctx.host { inherit host; });
  }) allHosts);

  renderedTraces = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: mermaid: ''
### ${name}

```mermaid
${mermaid}
```
'') allTraces);

in
{
  perSystem =
    { pkgs, ... }:
    let
      traceDrv = name: mermaid:
        pkgs.writeText "trace-${name}.md" ''
# Aspect Trace: ${name}

```mermaid
${mermaid}
```
'';

      readmeDrv = pkgs.writeText "README.md" ''
# Trace Demo: Adapter-Based Excludes, Substitutions, and Visualization

Demonstrates den's adapter composition patterns: excludes by name and provider,
aspect substitution, and resolution tracing with Mermaid diagrams.

## Hosts

| Host              | Adapter Pattern                              |
| ----------------- | -------------------------------------------- |
| `laptop`          | Baseline — no adapters, full tree            |
| `desktop-gdm`     | Substitute regreet → gdm                     |
| `web-server`      | Exclude nginx-exporter provider              |
| `mail-relay`      | Exclude monitoring by aspect reference       |
| `devbox`          | Exclude tailscale across two roles           |
| `provider-filter` | Exclude by meta.provider prefix              |
| `angle-brackets`  | Bracket includes + exclude adapter           |
| `multi-desktop`   | Multi-user: alice (hyprland) + bob (gnome)   |

## Legend

| Shape | Meaning |
| ----- | ------- |
| `([...])` | Host root |
| `[/...\]` | Provider sub-aspect |
| `[...]` | Aspect |
| dashed border | Excluded or replaced |

## Usage

```bash
nix run .#write-files     # writes traces/ and this README
nix build .#trace-laptop  # individual trace derivation
```

## Rendered Traces

${renderedTraces}
'';

      traceDrvs = lib.mapAttrs traceDrv allTraces;
    in
    {
      packages = lib.mapAttrs' (name: drv: lib.nameValuePair "trace-${name}" drv) traceDrvs // {
        write-files = pkgs.writeShellScriptBin "write-files" ''
          set -euo pipefail
          dest="$(${pkgs.git}/bin/git rev-parse --show-toplevel)/templates/trace-demo"
          mkdir -p "$dest/traces"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: drv: ''
            cat ${drv} > "$dest/traces/trace-${name}.md"
          '') traceDrvs)}
          cat ${readmeDrv} > "$dest/README.md"
        '';
      };

      files.gitToplevel = self;
      files.files =
        (lib.mapAttrsToList (name: drv: {
          path_ = "traces/trace-${name}.md";
          inherit drv;
        }) traceDrvs)
        ++ [{
          path_ = "README.md";
          drv = readmeDrv;
        }];
    };
}
