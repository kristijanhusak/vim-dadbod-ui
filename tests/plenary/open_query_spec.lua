describe('Open query', function()
  before_each(function()
    vim.fn.SetupTestDbs()
  end)

  after_each(function()
    vim.fn.Cleanup()
  end)

  it('should open new query buffer', function()
    vim.cmd('DBUI')
    vim.cmd('norm ojo')
    assert.are.same('sql', vim.bo.filetype)
    assert.are.same(vim.fn.getline(1), '')
  end)

  it('should open contacts table list query', function()
    vim.cmd('DBUI')
    vim.cmd('norm o3jojojo')
    assert.are.same('SELECT * from "contacts" LIMIT 200;', vim.fn.getline(1))
    assert.are.same('DBUI: dadbod_ui_test -> contacts', vim.fn['db_ui#statusline']())
    assert.are.same('dadbod_ui_test -> contacts', vim.fn['db_ui#statusline']({ prefix = '' }))
    assert.are.same('dadbod_ui_test / contacts', vim.fn['db_ui#statusline']({ prefix = '', separator = ' / ' }))
    assert.are.same('dadbod_ui_test', vim.fn['db_ui#statusline']({ prefix = '', show = { 'db_name' } }))
    assert.are.same('contacts', vim.b.dbui_table_name)
  end)

  it('should write query', function()
    vim.cmd('DBUI')
    vim.cmd('norm o3jojojo')
    assert.are.same('SELECT * from "contacts" LIMIT 200;', vim.fn.getline(1))
    vim.cmd('write')
    assert.is.True(vim.fn.bufname('.dbout'):len() > 0)
    assert.are.same(1, vim.fn.getwinvar(vim.fn.bufwinnr('.dbout'), '&previewwindow'))
    vim.cmd('pclose')
    vim.cmd('DBUI')
    vim.cmd('norm G')
    assert.are.same(vim.g.db_ui_icons.collapsed.saved_queries..' Query results (1)', vim.fn.getline('.'))
    vim.cmd('norm o')
    assert.are.same(vim.g.db_ui_icons.expanded.saved_queries..' Query results (1)', vim.fn.getline('.'))
    vim.cmd('norm j')
    assert.is.True(vim.fn.getline('.'):match(vim.g.db_ui_icons.tables..' %d+.dbout') ~= nil)
    assert.are.same(-1, vim.fn.bufwinnr('.dbout'))
    vim.cmd('norm o')
    assert.is.True(vim.fn.bufwinnr('.dbout') > -1)
  end)
end)
