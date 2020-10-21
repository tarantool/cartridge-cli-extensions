# Admin Extension

Contains `admin` module that allows to register functions to call them
via `cartridge admin` command.

## Usage

### Init

`admin.init()` - exposes functions that are used by `cartridge admin`.

### Register functions

`admin.register(func_name, func_usage, func_args, func_call)`

Arguments:

  * `func_name` (`string`, required) - name of function;

  * `func_usage` (`string`, required) - short function usage;

  * `func_args` (`table`, optional) - function arguments spec:

    ```lua
    {
        ['<arg-name>'] = {
            usage = '<arg-usage>',
            type = '<arg-type>',
        }
    }
    ```

    Supported argument types are: `string`, `number` and `boolean`.

  * `func_call` (`function`, required) - function callback.
    * Accepts one argument - `opts` table with arguments names as a keys.

    * In case of success returns `string` (of array or `string`s) - messages to
      be displayed by `cartirge admin`.

    * In case of error returns `nil, string_error`.

### Remove functions

`admin.remove(func_name)`

Removes `func_name` function if it is registered.

Always returns `true`.

## Example

Describe admin function in application:

```lua
local cli_admin = require('cartridge-cli-extensions.admin')

-- initialize admin module
cli_admin.init()

-- describe function that probes instance by URI
local probe = {
    usage = 'Probe instance',
    args = {
        uri = {
            type = 'string',
            usage = 'Instance URI',
        },
    },
    call = function(opts)
        opts = opts or {}

        if opts.uri == nil then
            return nil, "Please, pass instance URI via --uri flag"
        end

        local cartridge_admin = require('cartridge.admin')
        local ok, err = cartridge_admin.probe_server(opts.uri)

        if not ok then
            return nil, err.err
        end

        return {
            string.format('Probe %q: OK', opts.uri),
        }
    end,
}

-- register this function
local ok, err = cli_admin.register('probe', probe.usage, probe.args, probe.call)
assert(ok, err)
```

Get function help via `cartridge admin`:

```bash
cartridge admin --name APPNAME probe --help

   • Admin function "probe" usage:

Probe instance

Args:
  --uri string  Instance URI
```

Call function via `cartridge admin`:

```bash
cartridge admin --name APPNAME probe --uri localhost:3301

   • Probe "localhost:3301": OK
```
