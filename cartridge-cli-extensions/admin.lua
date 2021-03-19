local admin = {}

local registry = {}

local allowed_arg_types = {
    'string', 'number', 'boolean',
}

local allowed_arg_types_map = {}
for _, allowed_arg_type in ipairs(allowed_arg_types) do
    allowed_arg_types_map[allowed_arg_type] = true
end

local allowed_arg_types_str = table.concat(allowed_arg_types, ', ')

local function check_func_args(func_args)
    assert(type(func_args) == 'table')

    for arg_name, arg_spec in pairs(func_args) do
        if type(arg_name) ~= 'string' then
            return nil, string.format('Argument name should be string, got %s', arg_name)
        end

        if type(arg_spec) ~= 'table' then
            return nil, string.format('Argument spec should be table, got %s', arg_spec)
        end

        if type(arg_spec.usage) ~= 'string' then
            return nil, string.format('Argument usage should be string, got %s', arg_spec.usage)
        end

        if type(arg_spec.type) ~= 'string' then
            return nil, string.format('Argument type should be string, got %s', arg_spec.type)
        end

        if not allowed_arg_types_map[arg_spec.type] then
            return nil, string.format(
                'Argument type should be one of %s, got %s',
                allowed_arg_types_str, arg_spec.type
            )
        end
    end

    return true
end

-- prints values and performs box.session push
local function print_and_push(...)
    print(...)

    local args = {...}
    local args_strings = {}

    for i=1,select('#', ...) do
        table.insert(args_strings, tostring(args[i]))
    end

    box.session.push(table.concat(args_strings, '\t'))
end

function admin.register(func_name, func_usage, func_args, func_call)
    if type(func_name) ~= 'string' then
        return nil, string.format("func_name should be string")
    end

    if registry[func_name] ~= nil then
        return nil, string.format("Function %q is already registered", func_name)
    end

    if type(func_usage) ~= 'string' then
        return nil, string.format("func_usage should be string")
    end

    if func_args ~= nil then
        if  type(func_args) ~= 'table' then
            return nil, string.format("func_args should be table or nil")
        end

        local ok, err = check_func_args(func_args)
        if not ok then
            return nil, string.format("func_args passed in bad format: %s", err)
        end
    else
        func_args = nil  -- box.NULL
    end

    if type(func_call) ~= 'function' then
        return nil, string.format("func_call should be function")
    end

    registry[func_name] = {
        usage = func_usage,
        args = func_args,
        call = func_call,
    }

    return true
end

function admin.remove(func_name)
    if type(func_name) ~= 'string' then
        return nil, string.format("func_name should be string")
    end

    registry[func_name] = nil

    return true
end

-- functions that are exposed for `cartridge admin`

local function admin_list()
    local list = setmetatable({}, {__serialize = 'map'})

    for func_name, func_spec in pairs(registry) do
        list[func_name] = {
            usage = func_spec.usage,
        }
    end

    return list
end

local function admin_help(func_name)
    if type(func_name) ~= 'string' then
        return nil, string.format("func_name should be string")
    end

    if registry[func_name] == nil then
        return nil, string.format("Function %q isn't found", func_name)
    end

    return {
        usage = registry[func_name].usage,
        args = setmetatable(registry[func_name].args or {}, {__serialize = 'map'}),
    }
end

local function admin_call(func_name, opts)
    if type(func_name) ~= 'string' then
        return nil, string.format("func_name should be string")
    end

    if opts ~= nil and type(opts) ~= 'table' then
        return nil, string.format("opts should be table or nil")
    end

    if registry[func_name] == nil then
        return nil, string.format("Function %q isn't found", func_name)
    end

    assert(registry[func_name].call ~= nil)

    -- set print function
    local env = table.copy(_G)
    env.print = print_and_push
    setfenv(registry[func_name].call, env)

    local res, err = registry[func_name].call(opts)
    return res, err
end

function admin.init()
    rawset(_G, '__cartridge_admin_list', admin_list)
    rawset(_G, '__cartridge_admin_help', admin_help)
    rawset(_G, '__cartridge_admin_call', admin_call)
end

return admin
