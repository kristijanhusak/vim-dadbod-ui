let s:suite = themis#suite('Help')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetOptionVariable('db_ui_show_help', 1)
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call SetOptionVariable('db_ui_show_help', 0)
  call Cleanup()
endfunction

function! s:suite.should_show_help_text() abort
  :DBUI
  call s:expect(getline(1)).to_equal('" Press ? for help')
  call s:expect(getline(2)).to_be_empty()
  call s:expect(getline(3)).to_equal('▸ dadbod_ui_test')
  call s:expect(getline(4)).to_equal('▸ dadbod_ui_testing')
  normal ?

  call s:expect(getline(3)).to_equal('" o - Open/Toggle selected item')
  call s:expect(getline(4)).to_equal('" S - Open/Toggle selected item in vertical split')
  call s:expect(getline(5)).to_equal('" d - Delete selected item')
  call s:expect(getline(6)).to_equal('" R - Redraw')
  call s:expect(getline(7)).to_equal('" A - Add connection')
  call s:expect(getline(8)).to_equal('" H - Toggle database details')
  call s:expect(getline(9)).to_equal('" r - Rename/Edit buffer/connection/saved query')
  call s:expect(getline(10)).to_equal('" q - Close drawer')
  call s:expect(getline(11)).to_equal('" <C-j>/<C-k> - Go to last/first sibling', 'noaction', 'help', '', '', 0)
  call s:expect(getline(12)).to_equal('" K/J - Go to prev/next sibling', 'noaction', 'help', '', '', 0)
  call s:expect(getline(13)).to_equal('" <C-p>/<C-n> - Go to parent/child node', 'noaction', 'help', '', '', 0)
  call s:expect(getline(14)).to_equal('" <Leader>W - (sql) Save currently opened query')
  call s:expect(getline(15)).to_equal('" <Leader>E - (sql) Edit bind parameters in opened query')
  call s:expect(getline(16)).to_equal('" <Leader>S - (sql) Execute query in visual or normal mode')
  call s:expect(getline(17)).to_equal('" <C-]> - (.dbout) Go to entry from foreign key cell')
  call s:expect(getline(18)).to_equal('" <motion>ic - (.dbout) Operator pending mapping for cell value')
  call s:expect(getline(19)).to_equal('" <Leader>R - (.dbout) Toggle expanded view')
  normal ?
  call s:expect(getline(1)).to_equal('" Press ? for help')
  call s:expect(getline(2)).to_be_empty()
  call s:expect(getline(3)).to_equal('▸ dadbod_ui_test')
  call s:expect(getline(4)).to_equal('▸ dadbod_ui_testing')
endfunction
