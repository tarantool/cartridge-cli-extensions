package = 'cartridge-cli-extentions'
version = 'scm-1'
source  = {
    url = 'git+https://github.com/tarantool/cartridge-cli-extentions.git',
    branch = 'master',
}

dependencies = {
    'lua ~> 5.1',
}

build = {
    type = 'cmake',
    variables = {
        version = 'scm-1',
        TARANTOOL_INSTALL_LUADIR = '$(LUADIR)',
    },
}
