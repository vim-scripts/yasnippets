" Copyright © 2007, Valyaeff Valentin <hhyperr AT gmail DOT com>
" Yet another plugin for snippets
"     Version:    1.0 2007.07.15
"      Author:    Valyaeff Valentin <hhyperr AT gmail DOT com>
"     License:    GPL
"
" This is another simple plugin for snippets. Main advantage is convenience
" syntax for defining new snippets. It needs for vim compiled with +ruby
" option.
"
" Options
" -------
" g:yasnippets_expandkey - key for expanding snippets or jumping to next
" marker
"
" g:yasnippets_expandkey_insert - if it has value 1, then value of expandkey
" will be inserted if nothing to expand or jump; useful for <tab>, <space>,
" etc.
" 
" g:yasnippets_marker - marker wich will be displayed in the buffer
"
" g:yasnippets_file - file with user defined snippets
"
" Snippets file syntax
" --------------------
" setmarker '@@@' # marker to use in snippets definition (optional)
"
" defsnippet 'snippet_abbrev', :filetype1, :filetype2, 'snippet'
"   # First elemet is abbreviation for snippets, last element is snippet
"   # itself. Between are arbitrary number of file types in wich that snippet
"   # works.
"
" defsnippet 'time', :_, '\<c-r>=strftime(\"%Y.%m.%d %H:%M\")\<cr>'
"   # :_ means for all files.
"
" defsnippet 'for',  :c, :cpp, %q[
" for(@@@; @@@; @@@) {
" @@@
" }
" ]
"   # This is multiline snippet. EOL chars are automaticly converted to <cr>.
"   # '@@@' is marker for cursor position.  Note that you don't need to indent
"   # snippets, they will automaticly by vim.

if exists("loaded_yasnippets")
    finish
endif
let loaded_yasnippets = 1

let s:save_cpo = &cpo
set cpo&vim

if !exists("g:yasnippets_expandkey")
  let g:yasnippets_expandkey = "<tab>"
endif

if !exists("g:yasnippets_expandkey_insert")
  let g:yasnippets_expandkey_insert = 1
endif

if !exists("g:yasnippets_marker")
  let g:yasnippets_marker = ';;\*;;'
endif

if !exists("g:yasnippets_file")
  let g:yasnippets_file = "~/.vim/snippets.rb"
endif

let g:yasnippets = {}
let s:start_line = -1
let s:appended = 1

function! Jump()
  if s:start_line != -1
    call cursor(s:start_line, 1)
    let s:start_line = -1
  endif
  if match(getline('.'), g:yasnippets_marker) == 0
    execute "normal 0v".repeat('l', strlen(substitute(g:yasnippets_marker, '\', '', 'g'))-1)
    return "\<c-\>\<c-n>gvo\<c-g>"
  endif
  if search(g:yasnippets_marker) != 0
    normal 0
    call search(g:yasnippets_marker, 'c')
    normal v
    call search(g:yasnippets_marker, 'e')
    return "\<c-\>\<c-n>gvo\<c-g>"
  else
    if s:appended != 1 && g:yasnippets_expandkey_insert
      return "\<tab>"
    else
      return ''
    endif
  endif
endfunction

function! Expand()
  let s:appended = 1
  let last_word = substitute(getline('.')[:(col('.')-2)], '\zs.*\W\ze\w*$', '', 'g')
  if last_word != ''
    if has_key(g:yasnippets, &ft)
      if has_key(g:yasnippets[&ft], last_word)
        if match(g:yasnippets[&ft][last_word], g:yasnippets_marker) != -1
          let s:start_line = line('.')
        else
          let s:start_line = -1
        endif
        return "\<c-w>" . g:yasnippets[&ft][last_word]
      endif
    endif
    if has_key(g:yasnippets['_'], last_word)
      if match(g:yasnippets['_'][last_word], g:yasnippets_marker) != -1
        let s:start_line = line('.')
      else
        let s:start_line = -1
      endif
      return "\<c-w>" . g:yasnippets['_'][last_word]
    endif
  endif
  let s:appended = 0
  return ''
endfunction

exec "inoremap ".g:yasnippets_expandkey." <c-r>=Expand()<cr><c-r>=Jump()<cr>"

ruby <<END
$marker = '@@@'
$snippets = []

def setmarker(marker)
  $marker = marker
end

def defsnippet(*args)
  $snippets << args
end

load VIM::evaluate("g:yasnippets_file")

for snippet in $snippets
  text = snippet.last.strip.gsub("\n", '\<cr>').
    gsub($marker, VIM::evaluate("g:yasnippets_marker"))
  keyword = snippet.first
  for filetype in snippet[1..-2]
    if VIM::evaluate("has_key(g:yasnippets, '#{filetype}')").to_i == 0
      VIM::command("let g:yasnippets['#{filetype}'] = {}")
    end
    VIM::command("let g:yasnippets['#{filetype}']['#{keyword}'] = \"#{text}\"")
  end
end
END

let &cpo = s:save_cpo
