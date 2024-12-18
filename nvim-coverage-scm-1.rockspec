local MODREV, SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'nvim-coverage'
version = MODREV .. SPECREV

description = {
  summary = 'Displays coverage information in the sign column.',
  detailed = [[
    Displays coverage information in the sign column.
  ]],
  labels = { 'neovim', 'plugin', },
  homepage = 'http://github.com/andythigpen/nvim-coverage',
  license = 'MIT',
}

dependencies = {
  'lua == 5.1',
  'lua-xmlreader',
}

source = {
  url = 'git://github.com/andythigpen/nvim-coverage',
}

build = {
  type = 'builtin',
  copy_directories = {
    'doc',
  },
}
