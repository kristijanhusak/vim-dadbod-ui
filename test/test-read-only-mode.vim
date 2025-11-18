let s:suite = themis#suite('Read-only mode')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  call SetupTestDbs()
endfunction

function! s:suite.after() abort
  call Cleanup()
endfunction

function! s:suite.should_detect_mutation_queries() abort
  " Test INSERT detection
  call s:expect(db_ui#utils#is_query_mutation('INSERT INTO users VALUES (1, "test")')).to_be_true()
  call s:expect(db_ui#utils#is_query_mutation('insert into users values (1, "test")')).to_be_true()
  
  " Test UPDATE detection
  call s:expect(db_ui#utils#is_query_mutation('UPDATE users SET name = "test"')).to_be_true()
  
  " Test DELETE detection
  call s:expect(db_ui#utils#is_query_mutation('DELETE FROM users WHERE id = 1')).to_be_true()
  
  " Test DROP detection
  call s:expect(db_ui#utils#is_query_mutation('DROP TABLE users')).to_be_true()
  
  " Test ALTER detection
  call s:expect(db_ui#utils#is_query_mutation('ALTER TABLE users ADD COLUMN email VARCHAR(255)')).to_be_true()
  
  " Test CREATE TABLE detection
  call s:expect(db_ui#utils#is_query_mutation('CREATE TABLE users (id INT)')).to_be_true()
  
  " Test TRUNCATE detection
  call s:expect(db_ui#utils#is_query_mutation('TRUNCATE TABLE users')).to_be_true()
endfunction

function! s:suite.should_allow_select_queries() abort
  " Test SELECT queries are not mutations
  call s:expect(db_ui#utils#is_query_mutation('SELECT * FROM users')).to_be_false()
  call s:expect(db_ui#utils#is_query_mutation('select * from users where id = 1')).to_be_false()
  
  " Test SHOW queries
  call s:expect(db_ui#utils#is_query_mutation('SHOW TABLES')).to_be_false()
  call s:expect(db_ui#utils#is_query_mutation('SHOW DATABASES')).to_be_false()
  
  " Test DESCRIBE queries
  call s:expect(db_ui#utils#is_query_mutation('DESCRIBE users')).to_be_false()
endfunction

function! s:suite.should_handle_comments_in_queries() abort
  " Single line comments
  call s:expect(db_ui#utils#is_query_mutation("-- This is a comment\nINSERT INTO users VALUES (1, 'test')")).to_be_true()
  
  " Multi-line comments
  call s:expect(db_ui#utils#is_query_mutation("/* Multi\nline\ncomment */\nUPDATE users SET name = 'test'")).to_be_true()
  
  " Comments should not affect SELECT
  call s:expect(db_ui#utils#is_query_mutation("-- Comment\nSELECT * FROM users")).to_be_false()
  
  " Mutation keyword in comment should be ignored
  call s:expect(db_ui#utils#is_query_mutation("-- DELETE FROM users\nSELECT * FROM users")).to_be_false()
endfunction

function! s:suite.should_handle_with_clause() abort
  " WITH clause followed by mutation
  call s:expect(db_ui#utils#is_query_mutation("WITH tmp AS (SELECT * FROM users) INSERT INTO archive SELECT * FROM tmp")).to_be_true()
  
  " WITH clause followed by SELECT should not be mutation
  call s:expect(db_ui#utils#is_query_mutation("WITH tmp AS (SELECT * FROM users) SELECT * FROM tmp")).to_be_false()
endfunction

function! s:suite.should_handle_multi_statement_queries() abort
  " SELECT followed by DELETE should be blocked
  call s:expect(db_ui#utils#is_query_mutation("SELECT * FROM users;\nDELETE FROM users WHERE id = 1")).to_be_true()
  
  " DELETE followed by SELECT should be blocked
  call s:expect(db_ui#utils#is_query_mutation("DELETE FROM users WHERE id = 1;\nSELECT * FROM users")).to_be_true()
  
  " Multiple SELECT statements should be allowed
  call s:expect(db_ui#utils#is_query_mutation("SELECT * FROM users;\nSELECT * FROM posts")).to_be_false()
  
  " Mutation keyword in string literal should be ignored
  call s:expect(db_ui#utils#is_query_mutation("SELECT * FROM users WHERE name = 'DELETE'")).to_be_false()
endfunction
