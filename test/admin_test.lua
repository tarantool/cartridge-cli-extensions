local t = require('luatest')
local g = t.group('admin')

local admin = require('cartridge-cli-extensions.admin')

g.before_all(function()
    admin.init()
end)

g.after_each(function()
    local admin_list = rawget(_G, '__cartridge_admin_list')
    for func_name in pairs(admin_list()) do
        admin.remove(func_name)
    end
end)

g.test_register_bad_params = function()
    -- bad func_name
    local ok, err = admin.register(nil, 'usage', {}, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_name should be string")

    local ok, err = admin.register(123, 'usage', {}, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_name should be string")

    -- bad func_usage
    local ok, err = admin.register('name', nil, {}, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_usage should be string")

    local ok, err = admin.register('name', 123, {}, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_usage should be string")

    -- bad func_call
    local ok, err = admin.register('name', 'usage', {}, nil)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_call should be function")

    local ok, err = admin.register('name', 'usage', {}, 123)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_call should be function")

    -- bad func_args
    -- bad type
    local ok, err = admin.register('name', 'usage', 123, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "func_args should be table or nil")

    -- non-string keys
    local func_args = {
        arg1 = {usage = 'usage-1', type = 'string'},
        [2] = {usage = 'usage-2', type = 'string'},
    }
    local ok, err = admin.register('name', 'usage', func_args, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "Argument name should be string, got 2")

    -- non-table spec
    local func_args = {
        arg1 = 123,
        arg2 = {usage = 'usage-2', type = 'string'},
    }
    local ok, err = admin.register('name', 'usage', func_args, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "Argument spec should be table, got 123")

    -- non-string usage
    local func_args = {
        arg1 = {usage = 123, type = 'string'},
        arg2 = {usage = 'usage-2', type = 'string'},
    }
    local ok, err = admin.register('name', 'usage', func_args, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "Argument usage should be string, got 123")

    -- non-string type
    local func_args = {
        arg1 = {usage = 'usage-1', type = 'string'},
        arg2 = {usage = 'usage-2', type = 123},
    }
    local ok, err = admin.register('name', 'usage', func_args, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "Argument type should be string, got 123")

    -- unsupported type
    local func_args = {
        arg1 = {usage = 'usage-1', type = 'table'},
        arg2 = {usage = 'usage-2', type = 'string'},
    }
    local ok, err = admin.register('name', 'usage', func_args, function() end)
    t.assert_not(ok)
    t.assert_str_contains(err, "Argument type should be one of string, number, boolean, got table")
end

local func1 = {
    usage = 'Call some function w/o args',
    call = function() return 123 end
}

local func2 = {
    usage = 'Call some function w/ args',
    args = {
        arg1 = {usage = 'usage-1', type = 'string'},
        arg2 = {usage = 'usage-2', type = 'number'},
        arg3 = {usage = 'usage-3', type = 'boolean'},
    },
    call = function(opts) return opts end,
}

local function register_test_funcs()
    local ok, err = admin.register('func1', func1.usage, func1.args, func1.call)
    t.assert(ok, err)
    local ok, err = admin.register('func2', func2.usage, func2.args, func2.call)
    t.assert(ok, err)
end

g.test_register = function()
    register_test_funcs()

    -- try to register func1 again
    local ok, err = admin.register('func1', func1.usage, func1.args, func1.call)
    t.assert_not(ok)
    t.assert_str_contains(err, 'Function "func1" is already registered')
end

g.test_list = function()
    register_test_funcs()

    local admin_list = rawget(_G, '__cartridge_admin_list')

    -- get functions list
    t.assert_equals(admin_list(), {
        func1 = {usage = 'Call some function w/o args'},
        func2 = {usage = 'Call some function w/ args'},
    })
end

g.test_help = function()
    register_test_funcs()

    local admin_help = rawget(_G, '__cartridge_admin_help')

    -- bad func_name
    local help, err = admin_help()
    t.assert_equals(help, nil)
    t.assert_str_contains(err, 'func_name should be string')

    local help, err = admin_help(123)
    t.assert_equals(help, nil)
    t.assert_str_contains(err, 'func_name should be string')

    -- non-existent func
    local help, err = admin_help('non-existent-func')
    t.assert_equals(help, nil)
    t.assert_str_contains(err, 'Function "non-existent-func" isn\'t found')

    -- func w/o args
    local help, err = admin_help('func1')
    t.assert_equals(err, nil)
    t.assert_equals(help, {
        usage = func1.usage,
        args = nil,
    })

    -- func w/ args
    local help, err = admin_help('func2')
    t.assert_equals(err, nil)
    t.assert_equals(help, {
        usage = func2.usage,
        args = func2.args,
    })
end

g.test_call = function()
    register_test_funcs()

    local admin_call = rawget(_G, '__cartridge_admin_call')

    -- bad func_name
    local res, err = admin_call()
    t.assert_equals(res, nil)
    t.assert_str_contains(err, 'func_name should be string')

    local res, err = admin_call(123)
    t.assert_equals(res, nil)
    t.assert_str_contains(err, 'func_name should be string')

    -- bad opts
    local res, err = admin_call('func1', 123)
    t.assert_equals(res, nil)
    t.assert_str_contains(err, 'opts should be table or nil')

    -- non-existent func
    local res, err = admin_call('non-existent-func')
    t.assert_equals(res, nil)
    t.assert_str_contains(err, 'Function "non-existent-func" isn\'t found')

    -- call function w/o args
    local res, err = admin_call('func1')
    t.assert_equals(err, nil)
    t.assert_equals(res, 123)

    -- call function w/ args
    local opts = {
        arg1 = 'some-string',
        arg2 = 123,
        arg3 = true,
    }
    local res, err = admin_call('func2', opts)
    t.assert_equals(err, nil)
    t.assert_equals(res, opts)
end
