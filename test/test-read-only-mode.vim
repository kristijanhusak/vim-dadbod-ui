let s:suite = themis#suite('Read-only mode')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_detect_mutation_queries() abort
  call s:expect(db_ui#utils#is_query_mutation('INSERT INTO users VALUES (1, "test")')).to_be_true()
  call s:expect(db_ui#utils#is_query_mutation('UPDATE users SET name = "test"')).to_be_true()
  call s:expect(db_ui#utils#is_query_mutation('DELETE FROM users WHERE id = 1')).to_be_true()
  call s:expect(db_ui#utils#is_query_mutation('DROP TABLE users')).to_be_true()
  call s:expect(db_ui#utils#is_query_mutation('CREATE TABLE users (id INT)')).to_be_true()
endfunction

function! s:suite.should_allow_select_queries() abort
  call s:expect(db_ui#utils#is_query_mutation('SELECT * FROM users')).to_be_false()
  call s:expect(db_ui#utils#is_query_mutation('SHOW TABLES')).to_be_false()
  call s:expect(db_ui#utils#is_query_mutation('DESCRIBE users')).to_be_false()
endfunction

function! s:suite.should_handle_multi_statement_queries() abort
  " The original bug report case - SELECT followed by DELETE
  call s:expect(db_ui#utils#is_query_mutation("SELECT\n    *\nFROM\n    user_entity\nLIMIT 10;\n\nDELETE FROM user_entity WHERE user_id = 'x'")).to_be_true()
  
  call s:expect(db_ui#utils#is_query_mutation("SELECT * FROM users;\nDELETE FROM users WHERE id = 1")).to_be_true()
  call s:expect(db_ui#utils#is_query_mutation("SELECT * FROM users;\nSELECT * FROM posts")).to_be_false()
endfunction

function! s:suite.should_ignore_keywords_in_comments_and_strings() abort
  call s:expect(db_ui#utils#is_query_mutation("-- DELETE FROM users\nSELECT * FROM users")).to_be_false()
  call s:expect(db_ui#utils#is_query_mutation("SELECT * FROM users WHERE name = 'DELETE'")).to_be_false()
endfunction
