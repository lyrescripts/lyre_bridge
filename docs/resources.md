# Resource System

Lyre resources are convention-first. A normal resource identity file is only:

```lua
LyreBridge.registerResource("lyre_fuel")
```

The registry derives the rest from `lyre_bridge/resources/<resource>/`.

## Folder Contract

```text
resources/<resource>/
  resource.lua
  bridge/
    client/
      esx.lua          # only when this resource needs custom behavior
      qbox.lua
      qbcore.lua
      standalone.lua
      example.lua
    server/
      esx.lua
      qbox.lua
      qbcore.lua
      standalone.lua
      example.lua
  sql/
    import.sql
    import_esx.sql
    import_qb.sql
    import_qbcore.sql
    import_qbox.sql
    inventory_items/esx.sql
```

Side-prefixed names (`cl_esx.lua`, `sv_esx.lua`) are still accepted for
backwards compatibility, but new resources should use the unprefixed form
since the parent folder already identifies the side. Generic target shims
can use `bridge/client/client.lua`.

You do not need bridge files just to select ESX, QBCore, Qbox or Standalone.
The core registers default framework candidates and fetches their shared
objects automatically when a framework object is needed. Add a bridge adapter
only when the resource needs custom methods or a custom `init()`. The recommended
pattern is "no file = no override": only create the framework adapters you
actually need, and let the core hydrate the rest.

For custom methods, start the adapter with the small helper and let the core hydrate detection/init:

```lua
local bridge = LyreBridge.bridgeCandidate("QBOX")

function bridge:myResourceMethod()
    return true
end
```

## What Is Auto-Discovered

- Bridge adapters from `bridge/client` and `bridge/server`.
- Common SQL from `sql/import.sql`.
- Framework SQL from `sql/import_esx.sql`, `sql/import_qb.sql`, `sql/import_qbcore.sql`, and `sql/import_qbox.sql`.
- Optional inventory seeds from `sql/inventory_items/*.sql`; they skip cleanly when the target table is missing.

## Validation

The selected bridge is validated automatically. `setupBridge` infers the
resource-specific method contract as the **intersection** of methods declared
across every loaded resource adapter (i.e. only methods present in *all*
adapters are required). This avoids spurious failures when one adapter
intentionally adds a framework-specific method other adapters do not provide,
and lets `STANDALONE` load even when a resource only ships ESX/QBCORE/QBOX
adapters. The selected framework is then validated after shared defaults are
injected. If a method is missing, the error names the method, resource, side
and framework.

## Adding a Resource

1. Create `lyre_bridge/resources/<resource>/resource.lua`.
2. Add `LyreBridge.registerResource("<resource>")`.
3. Put SQL in the convention folders above.
4. Add bridge adapters only for resource-specific behavior.
5. Import `@lyre_bridge/imports/shared.lua`, then client/server imports in the resource manifest.
6. Call `setupClientBridge()` and `setupServerBridge()` once during startup.
7. Run `powershell -ExecutionPolicy Bypass -File tools\check_bridge_pack.ps1`.

## Custom Files

Only declare files manually when a resource cannot follow the convention:

```lua
LyreBridge.registerResource("my_resource", {
    bridge = {
        client = { "bridge/client/custom_framework.lua" },
    },
    sql = {
        files = {
            { id = "custom_schema", path = "sql/custom_schema.sql", required = true, order = 10 },
        },
    },
})
```

Prefer renaming to a convention file before adding manual entries.

If a resource must fail when no files are found, mark that contract explicitly:

```lua
LyreBridge.registerResource("my_resource", {
    bridge = {
        required = { client = true, server = true },
    },
    sql = {
        required = true,
    },
})
```

Use this only for resources that genuinely cannot run without custom adapters or SQL.

## Debug

- `lyre_bridge_check` validates registered resources, bridge files, SQL files and missing paths.
- `lyre_bridge_resource <resource>` prints the generated identity: folder, bridge file counts and SQL branches.
- `lyre_bridge_resource <resource> verbose` prints every discovered bridge and SQL file.
- `exports.lyre_bridge:GetResourceIdentity(resource)` returns the generated identity, including discovered file paths and default bridge candidates.
- `exports.lyre_bridge:GetActiveBridgeInfo(resource, side)` returns the active framework and method names remembered for a resource side.
- `lyre_bridge_sql <resource> force <framework>` retries SQL for one resource.
- Add `events` to `lyre_bridge_sql` only when the database supports MySQL EVENT privileges.
- `lyre_bridge_sql_status <resource>` prints recorded migration rows for one resource.
- Enable `set lyre_bridge:debug true` to see discovery and provider selection logs.
