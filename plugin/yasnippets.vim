" Copyright © 2007, Valyaeff Valentin <hhyperr AT gmail DOT com>
" Yet another plugin for snippets
"     Version:    2.0 2007.07.18
"      Author:    Valyaeff Valentin <hhyperr AT gmail DOT com>
"     License:    GPL
"
" <<< Documentation
"
" This is another simple plugin for snippets. Main advantage is "newline"
" snippets and convenience syntax for defining new snippets. It needs for vim
" compiled with +ruby option.
"
" Options
" -------
" g:yasnippets_expandkey - key for expanding snippets or jumping to next
" marker
"
" g:yasnippets_expandkey_insert - unless it has value "false", then it will be
" inserted if nothing to expand or jump; if g:yasnippets_expandkey is "<tab>"
" (or "<space>", etc), set it to "\<tab>"
"
" g:yasnippets_nlkey - key for expanding newline snippets (typically "<cr>",
" if you don't want expand snippets, hit <C-J>)
"
" g:yasnippets_nlkey_insert - same as yasnippets_expandkey_insert, but for
" newline snippets (typically "\<cr>")
" 
" g:yasnippets_marker - marker wich will be displayed in the buffer
"
" g:yasnippets_file - file with user defined snippets
"
" Newline snippets
" ----------------
" Perhaps you editing C file:
"   #include <std*lib.h>
" (* - cursor position)
" If you hit Enter, new include directive will be inserted:
"   #include <stdlib.h>
"   #include <*>
"
" Snippets file syntax
" --------------------
" setmarker '###'
"   # marker to use in snippets definition (optional, default is '@@@')
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
"
" defnlsnippet '^#include "___"', :c, '#include \"@@@\"'
" defnlsnippet '^#include <___>', :c, '#include <@@@>'
"   # This is newline snippet. First elemet is two regular expressions joined
"   # with ___ (you may change it, see below) for two parts of line, before
"   # and above the cursor.
"
" setdelimeter '|||'
"   # set delimeter for defnlsnippet (optional, default is '___')
"
" >>>

if exists("loaded_yasnippets")
    finish
endif
let loaded_yasnippets = 1

let s:save_cpo = &cpo
set cpo&vim

" <<<1 Variables
if !exists("g:yasnippets_expandkey")
  let g:yasnippets_expandkey = "<tab>"
endif

if !exists("g:yasnippets_nlkey")
  let g:yasnippets_nlkey = "<cr>"
endif

if !exists("g:yasnippets_expandkey_insert")
  let g:yasnippets_expandkey_insert = "\<tab>"
endif

if !exists("g:yasnippets_nlkey_insert")
  let g:yasnippets_nlkey_insert = "\<cr>"
endif

if !exists("g:yasnippets_marker")
  let g:yasnippets_marker = ';;\*;;'
endif

if !exists("g:yasnippets_file")
  let g:yasnippets_file = "~/.vim/snippets.rb"
endif

let g:yasnippets = {}
let g:yasnippets['_'] = {}
let g:yasnippets_nl = {}
let g:yasnippets_nl['_'] = []
let s:start_line = -1
let s:appended = 1

" <<<1 Jump
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
    if s:appended != 1 && g:yasnippets_expandkey_insert != "false"
      return g:yasnippets_expandkey_insert
    else
      return ''
    endif
  endif
endfunction

" <<<1 Expand
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

" <<<1 NLexpand
function! NLexpand()
  let s:appended = 1
  let s:start_line = -1
  let left_part = strpart(getline('.'), 0, col('.') - 1)
  let right_part = strpart(getline('.'), col('.') - 1, strlen(getline('.')))
  if has_key(g:yasnippets_nl, &ft)
    for item in g:yasnippets_nl[&ft]
      if match(left_part, item[0]) >= 0 && match(right_part, item[1]) >= 0
        return "\<Esc>o".item[2]."\<C-R>=Jump()\<CR>"
      endif
    endfor
  endif
  for item in g:yasnippets_nl['_']
    if match(left_part, item[0]) >= 0 && match(right_part, item[1]) >= 0
      return "\<Esc>o".item[2]."\<C-R>=Jump()\<CR>"
    endif
  endfor
  if g:yasnippets_nlkey_insert != "false"
    return g:yasnippets_nlkey_insert
  else
    return ''
  endif
endfunction

" <<<1 Mappings
exec "inoremap ".g:yasnippets_expandkey." <c-r>=Expand()<cr><c-r>=Jump()<cr>"
exec "inoremap ".g:yasnippets_nlkey." <c-r>=NLexpand()<cr>"

" <<<1 Read user snippets
ruby <<END
$marker = '@@@'
$delimeter = '___'
$snippets = []
$nlsnippets = []

def setmarker(marker)
  $marker = marker
end

def setdelimeter(delimeter)
  $delimeter = delimeter
end

def defsnippet(*args)
  $snippets << args
end

def defnlsnippet(*args)
  $nlsnippets << args
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

for snippet in $nlsnippets
  left, right = snippet.first.split($delimeter)
  text = snippet.last.gsub($marker, VIM::evaluate("g:yasnippets_marker"))
  for filetype in snippet[1..-2]
    if VIM::evaluate("has_key(g:yasnippets_nl, '#{filetype}')").to_i == 0
      VIM::command("let g:yasnippets_nl['#{filetype}'] = []")
    end
    VIM::command("let g:yasnippets_nl['#{filetype}'] += [['#{left}', '#{right}', \"#{text}\"]]")
  end
end
END
" >>>

let &cpo = s:save_cpo
" vim:fdm=marker fmr=<<<,>>>
