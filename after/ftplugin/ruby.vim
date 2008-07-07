if expand("%:t:r") =~ '^test_\|_test$'
    silent! compiler rubyunit
else
    silent! compiler ruby
endif
setlocal tw=79 isfname+=: makeprg=ruby\ -wc\ % keywordprg=ri
let &includeexpr = 'tolower(substitute(substitute('.&includeexpr.',"\\(\\u\\+\\)\\(\\u\\l\\)","\\1_\\2","g"),"\\(\\l\\|\\d\\)\\(\\u\\)","\\1_\\2","g"))'

" The never ending quest to easily add "end"s.  I do not like them
" automatically added.

" Strategy 1.  Key mapping to add new lines/"end" and position the cursor.
inoremap <buffer> <C-Z> <CR>end<C-O>O
inoremap <buffer> <C-CR> <CR>end<C-O>O

" Strategy 2.  Use surround.vim. surround_101 (e) is the most general.
let b:surround_66  = "{|\r|}"               " B
let b:surround_67  = "class \r\nend"        " C
let b:surround_68  = "do |\r|\nend"         " D
let b:surround_73  = "if \r\nelse\nend"     " I
let b:surround_77  = "module \r\nend"       " M
let b:surround_85  = "unless \r\nelse\nend" " U
let b:surround_87  = "until \r\nend"        " W
let b:surround_99  = "case \r\nend"         " c
let b:surround_100 = "do\r\nend"            " d
if &filetype == "ruby"
    let b:surround_5   = "\r\nend"          " <C-E>
    let b:surround_101 = "\r\nend"          " e
    let b:surround_69  = "begin\nend"       " E
endif
let b:surround_105 = "if \r\nend"           " i
let b:surround_109 = "def \r\nend"          " m(ethod)
let b:surround_117 = "unless \r\nend"       " u
let b:surround_119 = "while \r\nend"        " w
let b:surround_{char2nr(':')} = ":\r"

" Strategy 3.  Abbreviations that only fire on a <C-]> or <Tab> keypress.
function! s:addend(before,...)
    let default = a:0 ? a:1 : a:before
    let char = getchar(0)
    if char == 0 || char == 9
        return a:before.(char == 9 ? " " : "")."\<CR>end\<Up>\<End>"
        ".repeat("\<Left>",strlen(a:before))
    else
        return default . nr2char(char)
    endif
endfunction
function! s:doabbrs()
    let commands = "if\nunless\nwhile\nuntil\ndef\nmodule\nclass\nbegin\ncase\nfor\ndo\n"
    while commands != ""
        let command = matchstr(commands,'.\{-\}\ze\n')
        let commands = substitute(commands,'.\{-\}\n','','')
        exe "iabbrev <silent> <buffer> ".command." <C-R>=<SID>addend('".command."')<CR>"
    endwhile
endfunction
call s:doabbrs()

" Strategy 4.  Try to guess if end is needed

"inoremap <silent> <buffer> <CR> <C-R>=<SID>crend()<CR>
function! s:crend()
    let y = "\<CR>end\<C-O>O"
    let n = "\<CR>"
    let space = matchstr(getline('.'),'^\s*')
    let word  = matchstr(getline('.'),'^\s*\zs\w\+')
    if word =~# '^\%(def\|module\|class\)$'
        let line = searchpair('\<'.word.'\>','','\<end\>','Wn','<SID>synname() !~# "rubyDefine\\|rubyModule\\|rubyClass"')
        " even is false if no end was found, or if the end found was less
        " indented than the current line
        let even = strlen(matchstr(getline(line),'^\s*')) >= strlen(space)
        if line == 0
            let even = 0
        end
        let g:even = even
        let g:line = line
        if !even && line == line('.') + 1
            return y
        end
        if even || getline(line('.')+1) =~ '\S'
            return n
        endif
        return y
    endif
    return n
endfunction

"nnoremap <silent> <buffer> [m :<C-U>call <SID>searchsyn('\<def\>','rubyDefine','b')<CR>
"nnoremap <silent> <buffer> ]m :<C-U>call <SID>searchsyn('\<def\>','rubyDefine','')<CR>
"nnoremap <silent> <buffer> [M :<C-U>call <SID>searchsyn('\<end\>','rubyDefine','b')<CR>
"nnoremap <silent> <buffer> ]M :<C-U>call <SID>searchsyn('\<end\>','rubyDefine','')<CR>

"nnoremap <silent> <buffer> [[ :<C-U>call <SID>searchsyn('\<\%(class\<Bar>module\)\>','rubyModule\<Bar>rubyClass','b')<CR>
"nnoremap <silent> <buffer> ]] :<C-U>call <SID>searchsyn('\<\%(class\<Bar>module\)\>','rubyModule\<Bar>rubyClass','')<CR>
"nnoremap <silent> <buffer> [] :<C-U>call <SID>searchsyn('\<end\>','rubyModule\<Bar>rubyClass','b')<CR>
"nnoremap <silent> <buffer> ][ :<C-U>call <SID>searchsyn('\<end\>','rubyModule\<Bar>rubyClass','')<CR>

nnoremap <silent> <buffer> [{ :<C-U>call searchpair('\<do\>\<Bar>{','','\<end\>\<Bar>}','Wb','<SID>synname() !~# "rubyCurlyBlock\\<Bar>rubyControl"')<CR>
nnoremap <silent> <buffer> ]} :<C-U>call searchpair('\<do\>\<Bar>{','','\<end\>\<Bar>}','W', '<SID>synname() !~# "rubyCurlyBlock\\<Bar>rubyControl"')<CR>

function! s:searchsyn(pattern,syn,flags)
    norm! m'
    let i = 0
    let cnt = v:count ? v:count : 1
    while i < cnt
        let i = i + 1
        let line = line('.')
        let col  = col('.')
        let pos = search(a:pattern,'W'.a:flags)
        while pos != 0 && s:synname() !~# a:syn
            let pos = search(a:pattern,'W'.a:flags)
        endwhile
        if pos == 0
            call cursor(line,col)
            return
        endif
    endwhile
endfunction

function! s:synname()
    return synIDattr(synID(line('.'),col('.'),0),'name')
endfunction
