" EasyMotion - Vim motions on speed!
"
" Author: Kim Silkebækken <kim.silkebaekken+vim@gmail.com>
"         haya14busa <hayabusa1419@gmail.com>
" Source: https://github.com/Lokaltog/vim-easymotion
" Last Change: 16 Feb 2014.
"=============================================================================
" Saving 'cpoptions' {{{
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim
" }}}
" Init: {{{
function! EasyMotion#init()
    call EasyMotion#highlight#load()
    " Store previous motion info
    let s:previous = {}
    " Store previous operator-pending motion info for '.' repeat
    let s:dot_repeat = {}
    " Prepare 1-key Migemo Dictionary
    let s:migemo_dicts = {}
    let s:EasyMotion_is_active = 0
    call EasyMotion#reset()
    " Anywhere regular expression: {{{
    let re = '\v' .
        \    '(<.|^$)' . '|' .
        \    '(.>|^$)' . '|' .
        \    '(\l)\zs(\u)' . '|' .
        \    '(_\zs.)' . '|' .
        \    '(#\zs.)'
    " 1. word
    " 2. end of word
    " 3. CamelCase
    " 4. after '_' hoge_foo
    " 5. after '#' hoge#foo
    let g:EasyMotion_re_anywhere = get(g:, 'EasyMotion_re_anywhere', re)

    " Anywhere regular expression within line:
    let re = '\v' .
        \    '(<.|^$)' . '|' .
        \    '(.>|^$)' . '|' .
        \    '(\l)\zs(\u)' . '|' .
        \    '(_\zs.)' . '|' .
        \    '(#\zs.)'
    let g:EasyMotion_re_line_anywhere = get(g:, 'EasyMotion_re_line_anywhere', re)
    "}}}
    " For other plugin
    let s:EasyMotion_is_cancelled = 0
    " 0 -> Success
    " 1 -> Cancel
    let g:EasyMotion_ignore_exception = 0
    return ""
endfunction "}}}
" Reset: {{{
function! EasyMotion#reset()
    let s:flag = {
        \ 'within_line' : 0,
        \ 'dot_repeat' : 0,
        \ 'regexp' : 0,
        \ 'bd_t' : 0,
        \ 'find_bd' : 0,
        \ }
        " regexp: -> regular expression
        "   This value is used when multi input find motion. If this values is
        "   1, input text is treated as regexp.(Default: escaped)
        " bd_t: -> bi-directional 't' motion
        "   This value is used to re-define regexp only for bi-directional 't'
        "   motion
        " find_bd: -> bi-directional find motion
        "   This value is used to recheck the motion is inclusive or exclusive
        "   because 'f' & 't' forward find motion is inclusive, but 'F' & 'T'
        "   backward find motion is exclusive
    let s:current = {
        \ 'is_operator' : 0,
        \ 'is_search' : 0,
        \ 'dot_repeat_target_cnt' : 0,
        \ 'dot_prompt_user_cnt' : 0,
        \ 'changedtick' : 0,
        \ }
        " \ 'start_position' : [],
        " \ 'cursor_position' : [],

        " is_operator:
        "   Store is_operator value first because mode(1) value will be
        "   changed by some operation.
        " dot_* :
        "   These values are used when '.' repeat for automatically
        "   select marker/label characters.(Using count avoid recursive
        "   prompt)
        " changedtick:
        "   :h b:changedtick
        "   This value is used to avoid side effect of overwriting buffer text
        "   which will change b:changedtick value. To overwrite g:repeat_tick
        "   value(defined tpope/vim-repeat), I can avoid this side effect of
        "   conflicting with tpope/vim-repeat
        " start_position:
        "   Original, start cursor position.
        " cursor_position:
        "   Usually, this valuse is same with start_position, but in
        "   visualmode and 'n' key motion, this value could be different.
    return ""
endfunction "}}}
" Motion Functions: {{{
" -- Find Motion -------------------------
" Note: {{{
" num_strokes:
"   The number of input characters. Currently provide 1, 2, or -1.
"   '-1' means no limit.
" visualmode:
"   Vim script couldn't detect the function is called in visual mode by
"   mode(1), so tell whether it is in visual mode by argument explicitly
" direction:
"   0 -> forward
"   1 -> backward
"   2 -> bi-direction (handle forward & backward at the same time) }}}
function! EasyMotion#S(num_strokes, visualmode, direction) " {{{
    if a:direction == 1
        let is_inclusive = 0
    else
        " Note: Handle bi-direction later because 'f' motion is inclusive but
        " 'F' motion is exclusive
        let is_inclusive = mode(1) ==# 'no' ? 1 : 0
    endif
    let s:flag.find_bd = a:direction == 2 ? 1 : 0
    let re = s:findMotion(a:num_strokes, a:direction)
    if s:handleEmpty(re, a:visualmode) | return | endif
    call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', is_inclusive)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#T(num_strokes, visualmode, direction) " {{{
    if a:direction == 1
        let is_inclusive = 0
    else
        " Note: Handle bi-direction later because 't' motion is inclusive but
        " 'T' motion is exclusive
        let is_inclusive = mode(1) ==# 'no' ? 1 : 0
    endif
    let s:flag.find_bd = a:direction == 2 ? 1 : 0
    let re = s:findMotion(a:num_strokes, a:direction)
    if s:handleEmpty(re, a:visualmode) | return | endif
    if a:direction == 2
        let s:flag.bd_t = 1
    elseif a:direction == 1
        let re = '\('.re.'\)\zs.'
    else
        let re = '.\ze\('.re.'\)'
    endif
    call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', is_inclusive)
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- Word Motion -------------------------
function! EasyMotion#WB(visualmode, direction) " {{{
    "FIXME: inconsistent with default vim motion
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    call s:EasyMotion('\(\<.\|^$\)', a:direction, a:visualmode ? visualmode() : '', 0)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#WBW(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    call s:EasyMotion('\(\(^\|\s\)\@<=\S\|^$\)', a:direction, a:visualmode ? visualmode() : '', 0)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#E(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    let is_inclusive = mode(1) ==# 'no' ? 1 : 0
    call s:EasyMotion('\(.\>\|^$\)', a:direction, a:visualmode ? visualmode() : '', is_inclusive)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#EW(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    let is_inclusive = mode(1) ==# 'no' ? 1 : 0
    call s:EasyMotion('\(\S\(\s\|$\)\|^$\)', a:direction, a:visualmode ? visualmode() : '', is_inclusive)
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- JK Motion ---------------------------
function! EasyMotion#JK(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    "FIXME: support exclusive
    if g:EasyMotion_startofline
        call s:EasyMotion('^\(\w\|\s*\zs\|$\)', a:direction, a:visualmode ? visualmode() : '', 0)
    else
        let prev_column = getpos('.')[2] - 1
        call s:EasyMotion('^.\{,' . prev_column . '}\zs\(.\|$\)', a:direction, a:visualmode ? visualmode() : '', 0)
    endif
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#Sol(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    call s:EasyMotion('^\(\w\|\s*\zs\|$\)', a:direction, a:visualmode ? visualmode() : '', '')
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#Eol(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    call s:EasyMotion('\(\w\|\s*\zs\|.\|^\)$', a:direction, a:visualmode ? visualmode() : '', '')
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- Search Motion -----------------------
function! EasyMotion#Search(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    call s:EasyMotion(@/, a:direction, a:visualmode ? visualmode() : '', 0)
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- JumpToAnywhere Motion ---------------
function! EasyMotion#JumpToAnywhere(visualmode, direction) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    call s:EasyMotion( g:EasyMotion_re_anywhere, a:direction, a:visualmode ? visualmode() : '', 0)
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- Line Motion -------------------------
function! EasyMotion#SL(num_strokes, visualmode, direction) " {{{
    let s:flag.within_line = 1
    call EasyMotion#S(a:num_strokes, a:visualmode, a:direction)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#TL(num_strokes, visualmode, direction) " {{{
    let s:flag.within_line = 1
    call EasyMotion#T(a:num_strokes, a:visualmode, a:direction)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#WBL(visualmode, direction) " {{{
    let s:flag.within_line = 1
    call EasyMotion#WB(a:visualmode, a:direction)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#EL(visualmode, direction) " {{{
    let s:flag.within_line = 1
    call EasyMotion#E(a:visualmode, a:direction)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#LineAnywhere(visualmode, direction) " {{{
    let s:flag.within_line = 1
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    let re = g:EasyMotion_re_line_anywhere
    call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', 0)
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- User Motion -------------------------
function! EasyMotion#User(pattern, visualmode, direction, inclusive) " {{{
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    let is_inclusive = mode(1) ==# 'no' ? a:inclusive : 0
    let re = a:pattern
    call s:EasyMotion(re, a:direction, a:visualmode ? visualmode() : '', is_inclusive)
    return s:EasyMotion_is_cancelled
endfunction " }}}
" -- Repeat Motion -----------------------
function! EasyMotion#Repeat(visualmode) " {{{
    " Repeat previous motion with previous targets
    if s:previous ==# {}
        call s:Message("Previous targets doesn't exist")
        let s:EasyMotion_is_cancelled = 1
        return s:EasyMotion_is_cancelled
    endif
    let re = s:previous.regexp
    let direction = s:previous.direction
    let s:flag.within_line = s:previous.line_flag
    let s:flag.bd_t = s:previous.bd_t_flag
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    " FIXME: is_inclusive value is inappropriate but handling this value is
    " difficult and priorities is low because this motion maybe used usually
    " as a 'normal' motion.
    let is_inclusive = mode(1) ==# 'no' ? 1 : 0

    call s:EasyMotion(re, direction, a:visualmode ? visualmode() : '', is_inclusive)
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#DotRepeat(visualmode) " {{{
    " Repeat previous '.' motion with previous targets and operator
    if s:dot_repeat ==# {}
        call s:Message("Previous motion doesn't exist")
        let s:EasyMotion_is_cancelled = 1
        return s:EasyMotion_is_cancelled
    endif

    let re = s:dot_repeat.regexp
    let direction = s:dot_repeat.direction
    let is_inclusive = s:dot_repeat.is_inclusive
    let s:flag.within_line = s:dot_repeat.line_flag
    let s:flag.bd_t = s:dot_repeat.bd_t_flag

    let s:current.is_operator = 1
    for cnt in range(v:count1)
        let s:flag.dot_repeat = 1 " s:EasyMotion() always call reset
        silent call s:EasyMotion(re, direction, 0, is_inclusive)
    endfor
    return s:EasyMotion_is_cancelled
endfunction " }}}
function! EasyMotion#NextPrevious(visualmode, direction) " {{{
    " Move next/previous destination using previous motion regexp
    if s:previous ==# {}
        call s:Message("Previous targets doesn't exist")
        let s:EasyMotion_is_cancelled = 1
        return s:EasyMotion_is_cancelled
    endif
    let re = s:previous.regexp
    let search_direction = (a:direction >= 1 ? 'b' : '')

    if g:EasyMotion_move_highlight
        call EasyMotion#highlight#attach_autocmd()
        call EasyMotion#highlight#add_highlight(re, g:EasyMotion_hl_move)
    endif

    if ! empty(a:visualmode)
        " FIXME: blink highlight
        silent exec 'normal! gv'
    endif
    for i in range(v:count1)
        " Do not treat this motion as 'jump' motion
        keepjumps call searchpos(re, search_direction)
    endfor
    call EasyMotion#reset()
    " -- Activate EasyMotion ----------------- {{{
    let s:EasyMotion_is_active = 1
    call EasyMotion#attach_active_autocmd() "}}}
    return s:EasyMotion_is_cancelled
endfunction " }}}
" }}}
" Helper Functions: {{{
" -- Message -----------------------------
function! s:Message(message) " {{{
    echo 'EasyMotion: ' . a:message
endfunction " }}}
function! s:Prompt(message) " {{{
    echohl Question
    echo a:message . ': '
    echohl None
endfunction " }}}
" -- Save & Restore values ---------------
function! s:VarReset(var, ...) " {{{
    if ! exists('s:var_reset')
        let s:var_reset = {}
    endif

    if a:0 == 0 && has_key(s:var_reset, a:var)
        " Reset var to original value
        " setbufbar( or bufname): '' or '%' can be used for the current buffer
        call setbufvar("", a:var, s:var_reset[a:var])
    elseif a:0 == 1
        " Save original value and set new var value

        let new_value = a:0 == 1 ? a:1 : ''

        " Store original value
        let s:var_reset[a:var] = getbufvar("", a:var)

        " Set new var value
        call setbufvar("", a:var, new_value)
    endif
endfunction " }}}
function! s:SaveValue() "{{{
    call s:VarReset('&scrolloff', 0)
    call s:VarReset('&modified', 0)
    call s:VarReset('&modifiable', 1)
    call s:VarReset('&readonly', 0)
    call s:VarReset('&spell', 0)
    call s:VarReset('&virtualedit', '')
    call s:VarReset('&foldmethod', 'manual')
endfunction "}}}
function! s:RestoreValue() "{{{
    call s:VarReset('&scrolloff')
    call s:VarReset('&modified')
    call s:VarReset('&modifiable')
    call s:VarReset('&readonly')
    call s:VarReset('&spell')
    call s:VarReset('&virtualedit')
    call s:VarReset('&foldmethod')
endfunction "}}}
function! s:turn_off_hl_error() "{{{
    let s:error_hl = EasyMotion#highlight#capture('Error')
    call EasyMotion#highlight#turn_off(s:error_hl)
    let s:matchparen_hl = EasyMotion#highlight#capture('MatchParen')
    call EasyMotion#highlight#turn_off(s:matchparen_hl)
endfunction "}}}
function! s:turn_on_hl_error() "{{{
    if exists('s:error_hl')
        call EasyMotion#highlight#turn_on(s:error_hl)
        unlet s:error_hl
    endif

    if exists('s:matchparen_hl')
        call EasyMotion#highlight#turn_on(s:matchparen_hl)
        unlet s:matchparen_hl
    endif
endfunction "}}}
" -- Draw --------------------------------
function! s:SetLines(lines, key) " {{{
    for [line_num, line] in a:lines
        call setline(line_num, line[a:key])
    endfor
endfunction " }}}
" -- Get characters from user input ------
function! s:GetChar() " {{{
    let char = getchar()
    if char == 27
        " Escape key pressed
        redraw
        call s:Message('Cancelled')
        return ''
    endif
    return nr2char(char)
endfunction " }}}
" -- Find Motion Helper ------------------
function! s:findMotion(num_strokes, direction) "{{{
    " Find Motion: S,F,T
    let s:current.is_operator = mode(1) ==# 'no' ? 1: 0
    " store cursor pos because 'n' key find motion could be jump to offscreen
    let s:current.original_position = [line('.'), col('.')]
    let s:current.is_search = a:num_strokes == -1 ? 1: 0
    let s:flag.regexp = a:num_strokes == -1 ? 1 : 0 " TODO: remove?

    if g:EasyMotion_add_search_history && a:num_strokes == -1
        let s:previous['input'] = @/
    else
        let s:previous['input'] = get(s:previous, 'input', '')
    endif
    let input = EasyMotion#command_line#GetInput(
                    \ a:num_strokes, s:previous.input, a:direction)
    let s:previous['input'] = input

    " Check that we have an input char
    if empty(input)
        return ''
    endif

    let re = s:convertRegep(input)

    if g:EasyMotion_add_search_history && a:num_strokes == -1
        let history_re = substitute(re, '\\c\|\\C', '', '')
        let @/ = history_re "For textobject: 'gn'
        call histadd('search', history_re)
    endif

    return re
endfunction "}}}
function! s:convertRegep(input) "{{{
    " 1. regexp
    " 2. migemo
    " 3. smartsign
    " 4. smartcase
    let re = s:should_use_regexp() ? a:input : escape(a:input, '.$^~\[]')

    " Convert space to match only start of spaces
    if re ==# ' '
        let re = '\s\+'
    endif

    if s:should_use_migemo(a:input)
        let re = s:convertMigemo(re)
    endif

    if s:should_use_smartsign(a:input)
        let re = s:convertSmartsign(re, a:input)
    endif

    let case_flag = EasyMotion#helper#should_case_sensitive(
                        \ a:input, s:current.is_search) ? '\c' : '\C'
    let re = case_flag . re
    return re
endfunction "}}}
function! s:convertMigemo(re) "{{{
    let re = a:re

    if len(re) > 1
        " System cmigemo
        return EasyMotion#cmigemo#getMigemoPattern(re)
    endif

    " EasyMotion migemo one key dict
    if ! has_key(s:migemo_dicts, &l:encoding)
        let s:migemo_dicts[&l:encoding] = EasyMotion#helper#load_migemo_dict()
    endif
    if re =~# '^\a$'
        let re = get(s:migemo_dicts[&l:encoding], re, a:re)
    endif
    return re
endfunction "}}}
function! s:convertSmartsign(re, char) "{{{
    let smart_dict = s:load_smart_dict()
    let upper_sign = escape(get(smart_dict, a:char, ''), '.$^~')
    if upper_sign ==# ''
        return a:re
    else
        let re = a:re . '\|' . upper_sign
        return re
    endif
endfunction "}}}
function! s:convertSmartcase(re, char) "{{{
    let re = a:re
    if a:char =~# '\U' "nonuppercase
        return '\c' . re
    else "uppercase
        return '\C' . re
    endif
endfunction "}}}
function! s:should_use_regexp() "{{{
    return g:EasyMotion_use_regexp == 1 && s:flag.regexp == 1
endfunction "}}}
function! s:should_use_migemo(char) "{{{
    if ! g:EasyMotion_use_migemo || match(a:char, '\A') != -1
        return 0
    endif

    " TODO: use direction to improve
    if s:flag.within_line == 1
        let first_line = line('.')
        let end_line = line('.')
    else
        let first_line = line('w0')
        let end_line = line('w$')
    endif


    " Skip folded line and check if text include multibyte haracters
    for line in range(first_line, end_line)
        if EasyMotion#helper#is_folded(line)
            continue
        endif

        if EasyMotion#helper#include_multibyte_char(getline(line)) == 1
            return 1
        endif
    endfor

    return 0
endfunction "}}}
function! s:should_use_smartsign(char) "{{{
    if (exists('g:EasyMotion_use_smartsign_us')  ||
    \   exists('g:EasyMotion_use_smartsign_jp')) &&
    \  match(a:char, '\A') != -1
        return 1
    else
        return 0
    endif
endfunction "}}}

function! s:handleEmpty(input, visualmode) "{{{
    " if empty, reselect and return 1
    if empty(a:input)
        if ! empty(a:visualmode)
            silent exec 'normal! gv'
        endif
        let s:EasyMotion_is_cancelled = 1 " Cancel
        return 1
    endif
    return 0
endfunction "}}}
function! s:load_smart_dict() "{{{
    if exists('g:EasyMotion_use_smartsign_us')
        return g:EasyMotion#sticky_table#us
    elseif exists('g:EasyMotion_use_smartsign_jp')
        return g:EasyMotion#sticky_table#jp
    else
        return {}
    endif
endfunction "}}}
" -- Handle Visual Mode ------------------
function! s:GetVisualStartPosition(c_pos, v_start, v_end, search_direction) "{{{
    let vmode = mode(1)
    if vmode !~# "^[Vv\<C-v>]"
        throw 'Unkown visual mode:'.vmode
    endif

    if vmode ==# 'V' "line-wise Visual
        " Line-wise Visual {{{
        if a:v_start[0] == a:v_end[0]
            if a:search_direction == ''
                return a:v_start
            elseif a:search_direction == 'b'
                return a:v_end
            else
                throw 'Unkown search_direction'
            endif
        else
            if a:c_pos[0] == a:v_start[0]
                return a:v_end
            elseif a:c_pos[0] == a:v_end[0]
                return a:v_start
            endif
        endif
        "}}}
    else
        " Character-wise or Block-wise Visual"{{{
        if a:c_pos == a:v_start
            return a:v_end
        elseif a:c_pos == a:v_end
            return a:v_start
        endif

        " virtualedit
        if a:c_pos[0] == a:v_start[0]
            return a:v_end
        elseif a:c_pos[0] == a:v_end[0]
            return a:v_start
        elseif EasyMotion#helper#is_greater_coords(a:c_pos, a:v_start) == 1
            return a:v_end
        else
            return a:v_start
        endif
        "}}}
    endif
endfunction "}}}
" -- Others ------------------------------
function! s:is_cmdwin() "{{{
  return bufname('%') ==# '[Command Line]'
endfunction "}}}
function! s:should_use_wundo() "{{{
    " wundu cannot use in command-line window and
    " unless undolist is not empty
    return ! s:is_cmdwin() && undotree().seq_last != 0
endfunction "}}}
function! EasyMotion#attach_active_autocmd() "{{{
    " Reference: https://github.com/justinmk/vim-sneak
    augroup plugin-easymotion-active
        autocmd!
        autocmd InsertEnter,WinLeave,BufLeave <buffer>
            \ let s:EasyMotion_is_active = 0
            \  | autocmd! plugin-easymotion-active * <buffer>
        autocmd CursorMoved <buffer>
            \ autocmd plugin-easymotion-active CursorMoved <buffer>
            \ let s:EasyMotion_is_active = 0
            \  | autocmd! plugin-easymotion-active * <buffer>
    augroup END
endfunction "}}}
function! EasyMotion#is_active() "{{{
    return s:EasyMotion_is_active
endfunction "}}}
function! EasyMotion#activate(is_visual) "{{{
    let s:EasyMotion_is_active = 1
    call EasyMotion#attach_active_autocmd()
    call EasyMotion#highlight#add_highlight(s:previous.regexp,
                                          \ g:EasyMotion_hl_move)
    call EasyMotion#highlight#attach_autocmd()
    if a:is_visual == 1
        normal! gv
    endif
endfunction "}}}
"}}}
" Grouping Algorithms: {{{
let s:grouping_algorithms = {
\   1: 'SCTree'
\ , 2: 'Original'
\ }
" -- Single-key/closest target priority tree {{{
" This algorithm tries to assign one-key jumps to all the targets closest to the cursor.
" It works recursively and will work correctly with as few keys as two.
function! s:GroupingAlgorithmSCTree(targets, keys) "{{{
    " Prepare variables for working
    let targets_len = len(a:targets)
    let keys_len = len(a:keys)

    let groups = {}

    let keys = reverse(copy(a:keys))

    " Semi-recursively count targets {{{
        " We need to know exactly how many child nodes (targets) this branch will have
        " in order to pass the correct amount of targets to the recursive function.

        " Prepare sorted target count list {{{
            " This is horrible, I know. But dicts aren't sorted in vim, so we need to
            " work around that. That is done by having one sorted list with key counts,
            " and a dict which connects the key with the keys_count list.

            let keys_count = []
            let keys_count_keys = {}

            let i = 0
            for key in keys
                call add(keys_count, 0)

                let keys_count_keys[key] = i

                let i += 1
            endfor
        " }}}

        let targets_left = targets_len
        let level = 0
        let i = 0

        while targets_left > 0
            " Calculate the amount of child nodes based on the current level
            let childs_len = (level == 0 ? 1 : (keys_len - 1) )

            for key in keys
                " Add child node count to the keys_count array
                let keys_count[keys_count_keys[key]] += childs_len

                " Subtract the child node count
                let targets_left -= childs_len

                if targets_left <= 0
                    " Subtract the targets left if we added too many too
                    " many child nodes to the key count
                    let keys_count[keys_count_keys[key]] += targets_left

                    break
                endif

                let i += 1
            endfor

            let level += 1
        endwhile
    " }}}
    " Create group tree {{{
        let i = 0
        let key = 0

        call reverse(keys_count)

        for key_count in keys_count
            if key_count > 1
                " We need to create a subgroup
                " Recurse one level deeper
                let groups[a:keys[key]] = s:GroupingAlgorithmSCTree(a:targets[i : i + key_count - 1], a:keys)
            elseif key_count == 1
                " Assign single target key
                let groups[a:keys[key]] = a:targets[i]
            else
                " No target
                continue
            endif

            let key += 1
            let i += key_count
        endfor
    " }}}

    " Finally!
    return groups
endfunction "}}}
" }}}
" -- Original ---------------------------- {{{
function! s:GroupingAlgorithmOriginal(targets, keys)
    " Split targets into groups (1 level)
    let targets_len = len(a:targets)
    let keys_len = len(a:keys)

    let groups = {}

    let i = 0
    let root_group = 0
    try
        while root_group < targets_len
            let groups[a:keys[root_group]] = {}

            for key in a:keys
                let groups[a:keys[root_group]][key] = a:targets[i]

                let i += 1
            endfor

            let root_group += 1
        endwhile
    catch | endtry

    " Flatten the group array
    if len(groups) == 1
        let groups = groups[a:keys[0]]
    endif

    return groups
endfunction
" }}}

" -- Coord/key dictionary creation ------- {{{
function! s:CreateCoordKeyDict(groups, ...)
    " Dict structure:
    " 1,2 : a
    " 2,3 : b
    let sort_list = []
    let coord_keys = {}
    let group_key = a:0 == 1 ? a:1 : ''

    for [key, item] in items(a:groups)
        let key = group_key . key
        "let key = ( ! empty(group_key) ? group_key : key)

        if type(item) == 3 " List
            " Destination coords

            " The key needs to be zero-padded in order to
            " sort correctly
            let dict_key = printf('%05d,%05d', item[0], item[1])
            let coord_keys[dict_key] = key

            " We need a sorting list to loop correctly in
            " PromptUser, dicts are unsorted
            call add(sort_list, dict_key)
        else
            " Item is a dict (has children)
            let coord_key_dict = s:CreateCoordKeyDict(item, key)

            " Make sure to extend both the sort list and the
            " coord key dict
            call extend(sort_list, coord_key_dict[0])
            call extend(coord_keys, coord_key_dict[1])
        endif

        unlet item
    endfor

    return [sort_list, coord_keys]
endfunction
" }}}
" }}}
" Core Functions: {{{
function! s:PromptUser(groups) "{{{
    " Recursive
    let group_values = values(a:groups)

    " -- If only one possible match, jump directly to it {{{
    if len(group_values) == 1
        if mode(1) ==# 'no'
            " Consider jump to first match
            " NOTE: matchstr() handles multibyte characters.
            let s:dot_repeat['target'] = matchstr(g:EasyMotion_keys, '^.')
        endif
        redraw
        return group_values[0]
    endif
    " }}}
    " -- Prepare marker lines ---------------- {{{
    let lines = {}

    let coord_key_dict = s:CreateCoordKeyDict(a:groups)

    for dict_key in sort(coord_key_dict[0])
        let target_key = coord_key_dict[1][dict_key]
        let [line_num, col_num] = split(dict_key, ',')

        let line_num = str2nr(line_num)
        let col_num = str2nr(col_num)

        " Add original line and marker line
        if ! has_key(lines, line_num)
            let current_line = getline(line_num)
            let lines[line_num] = {
                \ 'orig': current_line,
                \ 'marker': current_line,
                \ 'mb_compensation': 0,
                \ }
        endif

        " Solve multibyte issues by matching the byte column
        " number instead of the visual column
        let col_num -= lines[line_num]['mb_compensation']

        " Compensate for byte difference between marker
        " character and target character
        "
        " This has to be done in order to match the correct
        " column; \%c matches the byte column and not display
        " column.
        let target_char_len = strdisplaywidth(
                                \ matchstr(lines[line_num]['marker'],
                                \          '\%' . col_num . 'c.'))
        let target_key_len = strdisplaywidth(target_key)


        let target_line_byte_len = strlen(lines[line_num]['marker'])

        let target_char_byte_len = strlen(matchstr(
                                            \ lines[line_num]['marker'],
                                            \ '\%' . col_num . 'c.'))

        if strlen(lines[line_num]['marker']) > 0
        " Substitute marker character if line length > 0
            let c = 0
            while c < target_key_len && c < 2
                if strlen(lines[line_num]['marker']) >= col_num + c
                    " Substitute marker character if line length > 0
                    if c == 0
                        let lines[line_num]['marker'] = substitute(
                            \ lines[line_num]['marker'],
                            \ '\%' . (col_num + c) . 'c.',
                            \ strpart(target_key, c, 1) . repeat(' ', target_char_len - 1),
                            \ '')
                    else
                        let lines[line_num]['marker'] = substitute(
                            \ lines[line_num]['marker'],
                            \ '\%' . (col_num + c) . 'c.',
                            \ strpart(target_key, c, 1),
                            \ '')
                    endif
                else
                    let lines[line_num]['marker'] .= strpart(target_key, c, 1)
                endif
                let c += 1
            endwhile
        else
        " Set the line to the marker character if the line is empty
            let lines[line_num]['marker'] = target_key
        endif

        " -- Highlight targets ------------------- {{{
        if target_key_len == 1
            call EasyMotion#highlight#add_highlight(
                \ '\%' . line_num . 'l\%' . col_num . 'c',
                \ g:EasyMotion_hl_group_target)
        else
            call EasyMotion#highlight#add_highlight(
                \ '\%' . line_num . 'l\%' . col_num . 'c',
                \ g:EasyMotion_hl2_first_group_target)
            call EasyMotion#highlight#add_highlight(
                \ '\%' . line_num . 'l\%' . (col_num + 1) . 'c',
                \ g:EasyMotion_hl2_second_group_target)
        endif
        "}}}

        " Add marker/target length difference for multibyte
        " compensation
        let lines[line_num]['mb_compensation'] +=
            \ (target_line_byte_len - strlen(lines[line_num]['marker']))
    endfor

    let lines_items = items(lines)
    " }}}

    " -- Put labels on targets & Get User Input & Restore all {{{
    " Save undo tree {{{
    let s:undo_file = tempname()
    if s:should_use_wundo()
        execute "wundo" s:undo_file
    endif
    "}}}
    try
        " Set lines with markers {{{
        call s:SetLines(lines_items, 'marker')
        redraw "}}}

        " Get target character {{{
        call s:Prompt('Target key')
        let char = s:GetChar()
        "}}}

        " Convert uppercase {{{
        if g:EasyMotion_use_upper == 1 && match(g:EasyMotion_keys, '\l') == -1
            let char = toupper(char)
        endif "}}}

        " Jump first target when Enter or Space key is pressed "{{{
        if (char ==# "\<CR>" && g:EasyMotion_enter_jump_first == 1) ||
        \  (char ==# " " && g:EasyMotion_space_jump_first == 1)
            " NOTE: matchstr() is multibyte aware.
            let char = matchstr(g:EasyMotion_keys, '^.')
        endif "}}}

        " For dot repeat {{{
        if mode(1) ==# 'no'
            " Store previous target when operator pending mode
            if s:current.dot_prompt_user_cnt == 0
                " Store
                let s:dot_repeat['target'] = char
            else
                " Append target chars
                let s:dot_repeat['target'] .= char
            endif
        endif "}}}

    finally
        " Restore original lines
        call s:SetLines(lines_items, 'orig')

        " Un-highlight targets {{{
        call EasyMotion#highlight#delete_highlight(
            \ g:EasyMotion_hl_group_target,
            \ g:EasyMotion_hl2_first_group_target,
            \ g:EasyMotion_hl2_second_group_target,
            \ )
        " }}}

        " Restore undo tree {{{
        if s:should_use_wundo() && filereadable(s:undo_file)
            silent execute "rundo" s:undo_file
            unlet s:undo_file
        else
            " Break undo history (undobreak)
            let old_undolevels = &undolevels
            set undolevels=-1
            call setline('.', getline('.'))
            let &undolevels = old_undolevels
            unlet old_undolevels
            " FIXME: Error occur by GundoToggle for undo number 2 is empty
            call setline('.', getline('.'))
        endif "}}}

        redraw
    endtry "}}}

    " -- Check if we have an input char ------ {{{
    if empty(char)
        throw 'Cancelled'
    endif
    " }}}
    " -- Check if the input char is valid ---- {{{
    if ! has_key(a:groups, char)
        throw 'Invalid target'
    endif
    " }}}

    let target = a:groups[char]

    if type(target) == 3
        " Return target coordinates
        return target
    else
        " Prompt for new target character
        let s:current.dot_prompt_user_cnt += 1
        return s:PromptUser(target)
    endif
endfunction "}}}
function! s:DotPromptUser(groups) "{{{
    " Get char from previous target
    let char = s:dot_repeat.target[s:current.dot_repeat_target_cnt]
    " For dot repeat target chars
    let s:current.dot_repeat_target_cnt += 1

    let target = a:groups[char]

    if type(target) == 3
        " Return target coordinates
        return target
    else
        " Prompt for new target character
        return s:PromptUser(target)
    endif
endfunction "}}}
function! s:EasyMotion(regexp, direction, visualmode, is_inclusive) " {{{
    " Store s:current original_position & cursor_position {{{
    " current cursor pos.
    let s:current.cursor_position = [line('.'), col('.')]
    " original start position.  This value could be changed later in visual
    " mode
    let s:current.original_position =
        \ get(s:current, 'original_position', s:current.cursor_position)
    "}}}

    let win_first_line = line('w0') " visible first line num
    let win_last_line  = line('w$') " visible last line num

    let targets = []

    " Store info for Repeat motion {{{
    if s:flag.dot_repeat != 1
        " Store Regular Expression
        let s:previous['regexp'] = a:regexp
        let s:previous['direction'] = a:direction
        let s:previous['operator'] = v:operator

        " Note: 'is_inclusive' value could be changed later when
        " bi-directional find motion depend on 'true' direction the cursor
        " will move.
        let s:previous['is_inclusive'] = a:is_inclusive

        " For special motion flag
        let s:previous['line_flag'] = s:flag.within_line
        let s:previous['bd_t_flag'] = s:flag.bd_t " bi-directional t motion
    endif "}}}

    " To avoid side effect of overwriting buffer for tpope/repeat
    " store current b:changedtick. Use this value later
    let s:current.changedtick = b:changedtick

    try
        " -- Reset properties -------------------- {{{
        " Save original value and set new value
        call s:SaveValue()
        call s:turn_off_hl_error()
        " }}}
        " Setup searchpos args {{{
        let search_direction = (a:direction >= 1 ? 'b' : '')
        let search_stopline = a:direction >= 1 ? win_first_line : win_last_line

        if s:flag.within_line == 1
            let search_stopline = s:current.original_position[0]
        endif
        "}}}

        " Handle visual mode {{{
        if ! empty(a:visualmode)
            " Decide at where visual mode start {{{
            normal! gv
            let v_start = [line("'<"),col("'<")] " visual_start_position
            let v_end   = [line("'>"),col("'>")] " visual_end_position

            let v_original_pos = s:GetVisualStartPosition(
                \ s:current.cursor_position, v_start, v_end, search_direction)
            "}}}

            " Reselect visual text {{{
            keepjumps call cursor(v_original_pos)
            exec "normal! " . a:visualmode
            keepjumps call cursor(s:current.cursor_position)
            "}}}
            " Update s:current.original_position
            let s:current.original_position = v_original_pos " overwrite original start positio
        endif "}}}

        " Handle bi-directional t motion {{{
        if s:flag.bd_t == 1
            let regexp = '\('.a:regexp.'\)\zs.'
        else
            let regexp = a:regexp
        endif
        "}}}

        " Construct match dict {{{
        while 1
            " Note: searchpos() has side effect which jump cursor position.
            "       You can disable this side effect by add 'n' flags,
            "       but in this case, it's better to allows jump side effect
            "       to gathering matched targets coordinates.
            let pos = searchpos(regexp, search_direction, search_stopline)

            " Reached end of search range
            if pos == [0, 0]
                break
            endif

            " Skip folded lines {{{
            if EasyMotion#helper#is_folded(pos[0])
                if search_direction ==# 'b'
                    keepjumps call cursor(foldclosed(pos[0]-1), 0)
                else
                    keepjumps call cursor(foldclosedend(pos[0]+1), 0)
                endif
                continue
            endif "}}}

            call add(targets, pos)
        endwhile
        "}}}

        " Handle bidirection "{{{
        " For bi-directional t motion {{{
        if s:flag.bd_t == 1
            let regexp = '.\ze\('.a:regexp.'\)'
        endif
        "}}}
        " Reconstruct match dict
        if a:direction == 2
            " Forward

            " Jump back cursor_position
            keepjumps call cursor(s:current.cursor_position[0],
                                \ s:current.cursor_position[1])

            let targets2 = []
            if s:flag.within_line == 0
                let search_stopline = win_last_line
            else
                let search_stopline = s:current.cursor_position[0]
            endif
            while 1
                " TODO: refactoring
                let pos = searchpos(regexp, '', search_stopline)
                " Reached end of search range
                if pos == [0, 0]
                    break
                endif

                " Skip folded lines {{{
                if EasyMotion#helper#is_folded(pos[0])
                    " Always forward
                    keepjumps call cursor(foldclosedend(pos[0]+1), 0)
                    continue
                endif
                "}}}

                call add(targets2, pos)
            endwhile
            " Merge match target dict"{{{
            let t1 = 0 " backward
            let t2 = 0 " forward
            let targets3 = []
            while t1 < len(targets) || t2 < len(targets2)
                " Forward -> Backward -> F -> B -> ...
                if t2 < len(targets2)
                    call add(targets3, targets2[t2])
                    let t2 += 1
                endif
                if t1 < len(targets)
                    call add(targets3, targets[t1])
                    let t1 += 1
                endif
            endwhile
            let targets = targets3
            "}}}
        endif
        "}}}
        " Handle no match"{{{
        let targets_len = len(targets)
        if targets_len == 0
            throw 'No matches'
        endif
        "}}}

        " Attach specific key as marker to gathered matched coordinates
        let GroupingFn = function('s:GroupingAlgorithm' . s:grouping_algorithms[g:EasyMotion_grouping])
        let groups = GroupingFn(targets, split(g:EasyMotion_keys, '\zs'))

        " -- Shade inactive source --------------- {{{
        if g:EasyMotion_do_shade && targets_len != 1 && s:flag.dot_repeat != 1
            if a:direction == 1
                " Backward
                let shade_hl_re = '\%'. win_first_line .'l\_.*\%#'
            elseif a:direction == 0
                " Forward
                let shade_hl_re = '\%#\_.*\%'. win_last_line .'l'
            elseif a:direction == 2
                " Both directions"
                let shade_hl_re = '\_.*'
            endif

            call EasyMotion#highlight#add_highlight(
                \ shade_hl_re, g:EasyMotion_hl_group_shade)
            if g:EasyMotion_cursor_highlight
                let cursor_hl_re = '\%#'
                call EasyMotion#highlight#add_highlight(cursor_hl_re,
                    \ g:EasyMotion_hl_inc_cursor)
            endif
        endif
        " }}}

        " -- Jump back before prompt for visual scroll {{{
        " Because searchpos() change current cursor position and
        " if you just use cursor(s:current.cursor_position) to jump back,
        " current line will become middle of line window
        if ! empty(a:visualmode)
            keepjumps call cursor(win_first_line,0)
            normal! zt
        else
            " for adjusting cursorline
            keepjumps call cursor(s:current.cursor_position)
        endif
        "}}}

        " -- Prompt user for target group/character {{{
        if s:flag.dot_repeat != 1
            let coords = s:PromptUser(groups)
            let s:previous_target_coord = coords
        else
            let coords = s:DotPromptUser(groups)
        endif
        "}}}

        " -- Update cursor position -------------- {{{
        " First, jump back cursor to original position
        keepjumps call cursor(s:current.original_position)

        " Consider EasyMotion as jump motion :h jump-motion
        normal! m`

        " Update selection for visual mode {{{
        if ! empty(a:visualmode)
            exec 'normal! ' . a:visualmode
        endif
        " }}}

        " For bi-directional motion, checking again whether the motion is
        " inclusive is necessary. This value will might be updated later
        let is_inclusive_check = a:is_inclusive
        " For bi-directional motion, store 'true' direction for dot repeat
        " to handling inclusive/exclusive motion
        if a:direction == 2
            let true_direction =
                \ EasyMotion#helper#is_greater_coords(
                \   s:current.original_position, coords) > 0 ?
                \ 0 : 1
                " forward : backward
        else
            let true_direction = a:direction
        endif

        if s:flag.dot_repeat == 1
            " support dot repeat {{{
            " Use visual mode to emulate dot repeat
            normal! v

            " Deal with exclusive {{{
            if s:dot_repeat.is_inclusive == 0
                " exclusive
                if s:dot_repeat.true_direction == 0 "Forward
                    let coords[1] -= 1
                elseif s:dot_repeat.true_direction == 1 "Backward
                    " Shift visual selection to left by making cursor one key
                    " left.
                    normal! hoh
                endif
            endif "}}}

            " Jump to destination
            keepjumps call cursor(coords[0], coords[1])

            " Execute previous operator
            let cmd = s:dot_repeat.operator
            if s:dot_repeat.operator ==# 'c'
                let cmd .= getreg('.')
            endif
            exec 'normal! ' . cmd
            "}}}
        else
            " Handle inclusive & exclusive {{{
            " Overwrite inclusive flag for special case {{{
            if s:flag.find_bd == 1 && true_direction == 1
                " Note: For bi-directional find motion s(f) & t
                " If true_direction is backward, the motion is 'exclusive'
                let is_inclusive_check = 0 " overwrite
                let s:previous.is_inclusive = 0 " overwrite
            endif "}}}
            if is_inclusive_check
                " Note: {{{
                " Inclusive motion requires that we eat one more
                " character to the right by forcing the motion to inclusive
                " if we're using a forward motion because
                " > :h exclusive
                " > Note that when using ':' any motion becomes characterwise
                " > exclusive.
                " and EasyMotion use ':'
                " See: h: o_v }}}
                normal! v
            endif " }}}

            " Adjust screen especially for visual scroll & offscreen search {{{
            " Otherwise, cursor line will move middle line of window
            keepjumps call cursor(win_first_line, 0)
            normal! zt

            " Jump to destination
            keepjumps call cursor(coords[0], coords[1])

            " To avoid side effect of overwriting buffer {{{
            " for tpope/vim-repeat
            " See: :h b:changedtick
            if exists('g:repeat_tick')
                if g:repeat_tick == s:current.changedtick
                    let g:repeat_tick = b:changedtick
                endif
            endif "}}}
        endif

        " Set tpope/vim-repeat {{{
        if s:current.is_operator == 1 &&
                \ !(v:operator ==# 'y' && match(&cpo, 'y') == -1)
            " Store previous info for dot repeat {{{
            let s:dot_repeat.regexp = a:regexp
            let s:dot_repeat.direction = a:direction
            let s:dot_repeat.line_flag = s:flag.within_line
            let s:dot_repeat.is_inclusive = is_inclusive_check
            let s:dot_repeat.operator = v:operator
            let s:dot_repeat.bd_t_flag = s:flag.bd_t " Bidirectional t motion
            let s:dot_repeat.true_direction = true_direction " Check inclusive
            "}}}
            silent! call repeat#set("\<Plug>(easymotion-dotrepeat)")
        endif "}}}

        " Highlight all the matches by n-key find motions {{{
        if s:current.is_search == 1 && s:current.is_operator == 0
            " It seems let &hlsearch=&hlsearch doesn't work when called
            " in script, so use :h feedkeys() instead.
            " Ref: :h v:hlsearch
            " FIXME: doesn't work with `c` operator
            call EasyMotion#helper#silent_feedkeys(
                                    \ ":let &hlsearch=&hlsearch\<CR>",
                                    \ 'hlsearch', 'n')
        endif "}}}

        call s:Message('Jumping to [' . coords[0] . ', ' . coords[1] . ']')
        let s:EasyMotion_is_cancelled = 0 " Success
        "}}}

    catch
        redraw

        " Show exception message
        if g:EasyMotion_ignore_exception != 1
            call s:Message(v:exception)
        endif

        " -- Restore original cursor position/selection {{{
        if ! empty(a:visualmode)
            silent exec 'normal! gv'
            keepjumps call cursor(s:current.cursor_position)
        else
            keepjumps call cursor(s:current.original_position)
        endif
        " }}}
        let s:EasyMotion_is_cancelled = 1 " Cancel
    finally
        " -- Restore properties ------------------ {{{
        call s:RestoreValue()
        call s:turn_on_hl_error()
        call EasyMotion#reset()
        " }}}
        " -- Remove shading ---------------------- {{{
        call EasyMotion#highlight#delete_highlight()
        " }}}

        if s:EasyMotion_is_cancelled == 0 " Success
            " -- Landing Highlight ------------------- {{{
            if g:EasyMotion_landing_highlight
                call EasyMotion#highlight#add_highlight(a:regexp,
                                                      \ g:EasyMotion_hl_move)
                call EasyMotion#highlight#attach_autocmd()
            endif "}}}
            " -- Activate EasyMotion ----------------- {{{
            let s:EasyMotion_is_active = 1
            call EasyMotion#attach_active_autocmd() "}}}
        endif
    endtry
endfunction " }}}
"}}}
" Call Init: {{{
call EasyMotion#init()
"}}}
" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" vim: fdm=marker:et:ts=4:sw=4:sts=4
