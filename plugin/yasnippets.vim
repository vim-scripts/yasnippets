" Yet another plugin for text snippets
"     Version:    3.0 2007.08.04
"     Author:     Valyaeff Valentin <hhyperr AT gmail DOT com>
"     License:    GPL
"
" Copyright 2007 Valyaeff Valentin
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.


" <<<1 Initialization
if exists("loaded_yasnippets")
    finish
endif
let loaded_yasnippets = 1

let s:save_cpo = &cpo
set cpo&vim

runtime plugin/imaps.vim

" <<<1 Variables
if !exists("g:yasnippets_nlkey")
    let g:yasnippets_nlkey = "<cr>"
endif

if !exists("g:yasnippets_nlkey_insert")
    let g:yasnippets_nlkey_insert = "\<cr>"
endif

if !exists("g:yasnippets_file")
    let g:yasnippets_file = "~/.vim/snippets.rb"
endif

let g:yasnippets_nl        = {}
let g:yasnippets_nl['all'] = []


" <<<1 FreezeIndent() and UnfreezeIndent() - not change indent
function! FreezeIndent()
    let b:yasnippets_indent_backup = &indentexpr
    setlocal indentexpr=-1
    return ''
endfunction
function! UnfreezeIndent()
    execute "setlocal indentexpr=" . b:yasnippets_indent_backup
    return ''
endfunction


" <<<1 NLexpand() - insert newline snippet
function! NLexpand()
    let left_part = strpart(getline('.'), 0, col('.') - 1)
    let right_part = strpart(getline('.'), col('.') - 1, strlen(getline('.')))
    if has_key(g:yasnippets_nl, &ft)
        for item in g:yasnippets_nl[&ft]
            if match(left_part, item[0]) >= 0 && match(right_part, item[1]) >= 0
                return "\<C-O>o\<C-R>=IMAP_PutTextWithMovement('" . item[2] . "', '<+', '+>')\<CR>"
            endif
        endfor
    endif
    for item in g:yasnippets_nl['all']
        if match(left_part, item[0]) >= 0 && match(right_part, item[1]) >= 0
            return "\<C-O>o\<C-R>=IMAP_PutTextWithMovement('" . item[2] . "', '<+', '+>')\<CR>"
        endif
    endfor
    return g:yasnippets_nlkey_insert
endfunction


" <<<1 s:loadskeleton(filetype) - load skeleton file by filetype
function! s:loadskeleton(filetype)
ruby <<END
    filename = VIM::evaluate("expand('%:p')")
    filetype = VIM::evaluate("a:filetype")

# <<<2 Skeleton class
    class Skeleton
        attr_reader :filename

        def initialize(filename, filetype)
            @filename = filename
        end

        def get_binding
            binding
        end

        def ask(prompt)
            return yield if @yes_to_all
            answer = VIM::evaluate("input('#{prompt} [y/n/a] ')").strip.downcase
            if answer =~ /(yes|y|all|a)/
                @yes_to_all = true if answer =~ /(all|a)/
                yield
            end
        end
    end

# <<<2 Include shared.rb
    VIM::evaluate("&runtimepath").
        split(",").
        collect {|directory| Dir.glob("#{directory}/skeletons/shared.rb")}.
        flatten.
        each {|file| load file}

# <<<2 Find skeletons
    skeletons = VIM::evaluate("&runtimepath").
        split(",").
        collect {|directory| ["#{filetype}", "#{filetype}-*", "all-*"].
            collect {|name| Dir.glob("#{directory}/skeletons/#{name}")}}.
        flatten.
        sort_by {|name| [(File.basename(name).
            sub(/^([^-]+).*$/, '\1') == filetype ? 1 : 0), File.basename(name)]}.
        reverse.
        select {|name| ((IO.readlines(name).last =~
            /filematch:\s*\{\{(\/.*\/)\}\}/ and filename !~ eval($1)) ? false : true)}

    if skeletons.length > 1
        answer = VIM::evaluate("inputlist(['There is more than one skeleton:', " +
            skeletons.
            zip((1..skeletons.length).to_a).
            collect {|name, number| "'#{number}. #{File.basename(name).sub(/^[^-]+-/, "").capitalize}'"}.
            join(", ") +
            "])").to_i
    else
        answer = skeletons.length
    end

# <<<2 Load skeletons
    if answer > 0 and answer <= skeletons.length
        skeleton_lines = IO.readlines(skeletons[answer - 1])
        skeleton_lines.pop if skeleton_lines.last =~ /\Wdelete_line\W/
        begin
            require 'erb'
        rescue LoadError
            VIM::command("echoerr 'ERB library not found'")
        else
            begin
                result = ERB.new(skeleton_lines.join, nil, '-').result(Skeleton.new(filename, filetype).get_binding)
            rescue Exception
                VIM::command("echoerr 'Error in skeleton: #{skeletons[answer - 1]}'")
            else
                result.gsub!('<+', VIM::evaluate("IMAP_GetPlaceHolderStart()"))
                result.gsub!('+>', VIM::evaluate("IMAP_GetPlaceHolderEnd()"))
                result.split("\n").each_with_index do |line, number|
                    if number == 0
                        VIM::Buffer.current[1] = line
                    else
                        VIM::Buffer.current.append(number, line)
                    end
                end
                VIM::command("call cursor(1, 1)")
                VIM::command("set nomodified")
                VIM::command("execute \"normal i\\<c-r>=IMAP_Jumpfunc('', 0)\\<CR>\"")
            end
        end
    end
END
endfunction


" <<<1 Mappings and autocommands
exec "inoremap ".g:yasnippets_nlkey." <c-r>=NLexpand()<cr>"
exec "autocmd Syntax * syntax region Todo display oneline keepend"
    \ "start=/" . IMAP_GetPlaceHolderStart() . "/"
    \ "end=/" . IMAP_GetPlaceHolderEnd() . "/"
augroup skeleton
    autocmd!
    autocmd FileType * if line2byte(line('$') + 1) == -1 | call s:loadskeleton(&filetype) | endif
augroup END


" <<<1 Read user snippets
ruby <<END
$delimeter      = '___'
$snippets       = []
$nlsnippets     = []
$expand_pattern = 'keywordss'
$snippets_file  = VIM::evaluate("g:yasnippets_file")

def setdelimeter(delimeter)
    $delimeter = delimeter
end

def expand(new_pattern)
    if not new_pattern.include? 'keyword'
        VIM::command("echoerr 'Error in #$snippets_file: \"#{new_pattern}\" must contain \"keyword\"'")
    elsif block_given?
        old_pattern = $expand_pattern
        $expand_pattern = new_pattern
        yield
        $expand_pattern = old_pattern
    else
        $expand_pattern = new_pattern
    end
end

def defsnippet(*args)
    keyword = $expand_pattern.sub('keyword', args.shift)
    $snippets << [keyword] + args
end

def defnlsnippet(*args)
    $nlsnippets << args
end

load $snippets_file

for snippet in $snippets
    keyword = snippet.shift
    text = snippet.pop.strip.gsub("\n", '\<cr>')
    text.gsub!(/\^\^\^\\<cr>/, "\\<C-R>=FreezeIndent()\\<CR>\\<CR>\\<C-R>=UnfreezeIndent()\\<CR>")
    for filetype in snippet
        filetype = '' if filetype.to_s == 'all'
        VIM::command("call IMAP('#{keyword}', \"#{text}\", '#{filetype}', '<+', '+>')")
    end
end

for snippet in $nlsnippets
    left, right = snippet.first.split($delimeter)
    text = snippet.last
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
