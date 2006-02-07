" ==============================================================================
" Name:          ShowPairs
" Description:   Highlights the pair surrounding the current cursor location.
" Maintainer:    Anthony Kruize <trandor@gmail.com>
" Version:       2.1
" Modified:      8 February 2006
" ChangeLog:     See :help showpairs-changelog
"
" Usage:         Copy this file into the plugin directory so it will be
"                automatically sourced.
"
" Configuration: ***********************************************************
"                * PLEASE read the included help file(showpairs.txt) for a *
"                * more thorough explanation of how to use ShowPairs.      *
"                ***********************************************************
"                If you'd like to have the pair to the character just entered
"                in insert mode highlighted, the 'showmatch' and 'matchtime'
"                global options can be used.
"                For more information see  :help showmatch
"
"                To enable or disable ShowPairs while editing, map a key
"                sequence to the command 'ShowPairsToggle'
"                Example: map <F5> :ShowPairsToggle<cr>
"
"                The following options can be used to customize the behaviour
"                of ShowPairs.  Simply include them in your vimrc file with
"                the desired settings.
"
"                showpairs_enable    (Default: 1)
"                   Defines whether ShowPairs is enabled by default or not.
"                   Example: let g:showpairs_enable=0
"
"                showpairs_limit     (Default: 150)
"                   Defines the number of lines to search on either side of
"                   the cursor.
"                   Example: let g:showpairs_limit=20
"
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showpairs" )
	finish
endif
let loaded_showpairs = 1

" Options: Set up some nice defaults
if !exists('g:showpairs_enable'  ) | let g:showpairs_enable   = 1   | endif
if !exists('g:showpairs_limit'   ) | let g:showpairs_limit    = 150 | endif

" Not used yet: see s:pairs/opairs/cpairs below
if !exists('g:showpairs_pairs')
	let g:showpairs_pairs = "(:),{:},[:],<:>,#ifdef:#endif"
endif

" Commands
com! -nargs=0 ShowPairsToggle :silent call <sid>ShowPairsToggle()

" Initialize globals
let s:pairs  = substitute(&mps,",","","g")
let s:opairs = substitute(s:pairs,":.","","g")
let s:cpairs = substitute(s:pairs,".:","","g")
let s:pairs  = substitute(s:pairs,":","","g")
" Special case for '[' and ']'
if( match(s:opairs,"[") > 0 )
	let s:opairs = "[".substitute(s:opairs,"[","","")
endif
if( match(s:cpairs,"]") > 0 )
	let s:cpairs = "]".substitute(s:cpairs,"]","","")
endif
if( match(s:pairs,"]") > 0 )
	let s:pairs  = "]".substitute(s:pairs,"]","","")
endif
let s:pairs = "[".s:pairs."]"
let s:oln   = -1
let s:ocl   = -1
let s:cln   = -1
let s:ccl   = -1

" AutoCommands: Only if ShowPairs is enabled
if g:showpairs_enable == 1
	aug ShowPairs
		au!
		autocmd CursorHold * call s:ShowPairs()
" For Vim 7 only		autocmd InsertEnter * match none
	aug END
endif

" Highlighting: Set up some nice colours to show the pairs (by default we'll bold them)
"hi default ShowPairsHL ctermfg=white ctermbg=bg cterm=bold guifg=white guibg=bg gui=bold
"hi default ShowPairsHLp ctermfg=white ctermbg=bg cterm=bold guifg=white guibg=bg gui=bold
hi default ShowPairsHL cterm=bold gui=bold
hi default ShowPairsHLp cterm=bold gui=bold
hi default link ShowPairsHLe Error

" Function: ShowPairsToggle()
" Description: Toggles whether pairs are highlighted or not.
fun! s:ShowPairsToggle()
	let g:showpairs_enable = !g:showpairs_enable
	if g:showpairs_enable == 1
		aug ShowPairs
			autocmd CursorHold * call s:ShowPairs()
		aug END
	else
		match none
		aug ShowPairs
			au!
		aug END
	endif
endf

" Function: Showpairs()
" Description: Highlights the pair that the cursor is currently inside.
" Version 1.x used searchpair() to do it's magic, but the problem is that it
" moves the cursor around and affects the jump list which is undesirable.
" This version does it's own searching, hence the more complicated implementation.
fun! s:ShowPairs()
	if g:showpairs_enable == 1
		match none

		let ch = strpart(getline(line('.')), col('.') - 1, 1)
		if strlen(ch) && match(s:opairs, ch) > -1
			call <sid>FindUnMatchedClosingPair(strpart(s:cpairs, match(s:opairs, ch), 1))
			if s:ccl > -1
				exe 'match ShowPairsHL /\%'.line('.').'l\%'.col('.').'c\|\%'.s:cln.'l\%'.s:ccl.'c/'
			endif
		elseif strlen(ch) && match(s:cpairs, ch) > -1
			call <sid>FindUnMatchedOpeningPair(strpart(s:opairs, match(s:cpairs, ch), 1))
			if s:ocl > -1
				exe 'match ShowPairsHL /\%'.s:oln.'l\%'.s:ocl.'c\|\%'.line('.').'l\%'.col('.').'c/'
			endif
		else
			let opair = s:FindUnMatchedOpeningPair(s:opairs)
			if s:ocl > -1
				call <sid>FindUnMatchedClosingPair(strpart(s:cpairs, match(s:opairs, opair), 1))
				if s:ccl > -1
					exe 'match ShowPairsHLp /\%'.s:oln.'l\%'.s:ocl.'c\|\%'.s:cln.'l\%'.s:ccl.'c/'
				else
					exe 'match ShowPairsHLe /\%'.s:oln.'l\%'.s:ocl.'c/'
				endif
			else
				call <sid>FindUnMatchedClosingPair(s:cpairs)
				if s:ccl > -1
					exe 'match ShowPairsHLe /\%'.s:cln.'l\%'.s:ccl.'c/'
				endif
			endif
		endif
	endif
endf

" Function: FindUnMatchedOpeningPair()
fun! s:FindUnMatchedOpeningPair(opairs)
	let found = 0
	let pos = col('.')
	let curline = line('.')
	let line_count = 0
	let ch = ''
	let charpos = 0

	while found == 0 && line_count < g:showpairs_limit
		let str = getline(curline - line_count)
		while pos > -1
			let pos = <sid>Matchr(str, s:pairs, pos - 1)
			if pos > -1
				let ch = strpart(str, pos - 1, 1)
				if match(s:cpairs, ch) == -1
					if match(a:opairs, ch) > -1
						let p = match(s:opairs, ch)
						if exists('count_'.p) == 0
							let count_{p} = 0
						endif
						if count_{p} <= 0
							let found = 1
							let charpos = pos
							let pos = -1
						else
							let count_{p} = count_{p} - 1
						endif
					endif
				else
					let p = match(s:cpairs, ch)
					if exists('count_'.p) == 0
						let count_{p} = 0
					endif
					let count_{p} = count_{p} + 1
				endif
			endif
		endw
		let line_count = line_count + 1
		let pos = match(getline(curline - line_count), "$") + 1
	endw
	if found == 1
		let s:oln = curline - line_count + 1
		let s:ocl = charpos
		return ch
	else
		let s:oln = -1
		let s:ocl = -1
	endif
endf

" Function: FindUnMatchedClosingPair()
fun! s:FindUnMatchedClosingPair(cpairs)
	let found = 0
	let pos = col('.')
	let curline = line('.')
	let line_count = 0
	let ch = ''
	let charpos = 0

	while found == 0 && line_count < g:showpairs_limit
		let str = getline(curline + line_count)
		while pos > -1
			let pos = matchend(str, s:pairs, pos)
			if pos > -1
				let ch = strpart(str, pos - 1,1)
				if match(s:opairs, ch) == -1
					if match(a:cpairs, ch) > -1
						let p = match(s:cpairs, ch)
						if exists('count_'.p) == 0
							let count_{p} = 0
						endif
						if count_{p} <= 0
							let found = 1
							let charpos = pos
							let pos = -1
						else
							let count_{p} = count_{p} - 1
						endif
					endif
				else
					let p = match(s:opairs, ch)
					if exists('count_'.p) == 0
						let count_{p} = 0
					endif
					let count_{p} = count_{p} + 1
				endif
			endif
		endw
		let line_count = line_count + 1
		let pos = 0
	endw
	if found == 1
		let s:cln = curline + line_count - 1
		let s:ccl = charpos
		return ch
	else
		let s:cln = -1
		let s:ccl = -1
	endif
endf

" Function: Matchr()
" Parameters: expr  - Specifies the string to search
"             pat   - specifies the pattern to search for.
"             start - Specifies the position to search from.
" Description: Behaves similar to match() but searches backwards.
fun! s:Matchr(expr, pat, start)
	let npos = -1
	let pos = matchend(a:expr, a:pat)
	while pos > -1 && pos <= a:start
		let npos = pos
		let pos = matchend(a:expr, a:pat, pos)
	endw
	return npos
endf

" -----------------------------------------------------------------------------
" vim:ts=4:sw=4:noet
" HelpExtractor:
set lz
let docdir = substitute(expand("<sfile>:r").".txt",'\<plugin[/\\].*$','doc','')
if !isdirectory(docdir)
 if has("win32")
  echoerr 'Please make '.docdir.' directory first'
  unlet docdir
  finish
 elseif !has("mac")
  exe "!mkdir ".docdir
 endif
endif

let curfile = expand("<sfile>:t:r")
let docfile = substitute(expand("<sfile>:r").".txt",'\<plugin\>','doc','')
exe "silent! 1new ".docfile
silent! %d
exe "silent! 0r ".expand("<sfile>:p")
silent! 1,/^" HelpExtractorDoc:$/d
exe 'silent! %s/%FILE%/'.curfile.'/ge'
exe 'silent! %s/%DATE%/'.strftime("%b %d, %Y").'/ge'
norm! Gdd
silent! wq!
exe "helptags ".substitute(docfile,'^\(.*doc.\).*$','\1','e')

exe "silent! 1new ".expand("<sfile>:p")
1
silent! /^" HelpExtractor:$/,$g/.*/d
silent! wq!

set nolz
unlet docdir
unlet curfile
"unlet docfile
finish
" ---------------------------------------------------------------------
" Put the help after the HelpExtractorDoc label...
" HelpExtractorDoc:
*showpairs.txt* Highlights the pair surrounding the cursor.

               By Anthony Kruize <trandor@gmail.com>

ShowPairs highlights pairs surrounding the current cursor position.
The main goal of this script is to highlight matching braces and parenthesis
making it easier to edit nested expressions.

ShowPairs uses the |matchpairs| global option to determine which pairs to
highlight. To make ShowPairs highlight a specific pair, simply add it to the
|matchpairs| option.

ShowPairs is activated by the |CursorHold| |autocommand| which is triggered
every |updatetime| milliseconds.  This is set to 4000(4 seconds) by default.
If this is too slow, setting it to a lower value will make it more responsive.

===============================================================================
1. Contents                                    *showpairs* *showpairs-contents*

    1. Contents	             |showpairs-contents|
    2. Configuration         |showpairs-configuration|
    3. Highlighting          |showpairs-highlighting|
    4. Commands              |showpairs-commands|
    5. ChangeLog             |showpairs-changelog|

    Appendix
    A. Using matchpairs      |matchpairs|
    B. Defining updatetime   |updatetime|
    C. Defining a mapleader  |mapleader|
    D. Defining highlighting |highlight|

===============================================================================
2. Configuration                                      *showpairs-configuration*

ShowPairs can be configured to suit your needs.
The following options can be added to your |vimrc| to change how ShowPairs
behaves:

                                                           *'showpairs_enable'*
'showpairs_enable'      boolean (default: 1)
                        global
   This option enables or disables ShowPairs on startup. Normally ShowPairs
   will be enabled when Vim starts, setting this to 0 will disable ShowPairs
   by default.
   ShowPairs can be turned back on using the |ShowPairsToggle| command.

                                                            *'showpairs_limit'*
'showpairs_limit'       integer (default: 150)
                        global
   This option specifies the number of lines that ShowPairs will scan on either
   side of the current line for pairs.

===============================================================================
3. Highlighting                                        *showpairs-highlighting*

ShowPairs uses the following highlighting group to define the colours used to
highlight the matched pairs.

  - ShowPairsHL  : This group is used to highlight the pair surrounding the
                   cursor.
  - ShowPairsHLp : This group is used to highlight the pair to the character
                   under the cursor.
  - ShowPairsHLe : This group is used to highlight an unmatched pair.

You can define your own highlighting for these groups in your |vimrc|.
For example: >

  highlight ShowPairsHL guifg=red guibg=green gui=bold
<
See |highlight| for more information.

===============================================================================
4. Commands                                                *showpairs-commands*

                                                              *ShowPairsToggle*
:ShowPairsToggle
   This command will toggle the display of matching pairs on or off.

===============================================================================
5. ChangeLog                                              *showpairs-changelog*

2.1 - 2006-02-08
  Fixed the highlighting so it works when 'fg' and 'bg' aren't yet defined.
  Fixed InsertEnter being a Vim 7 only event...oops.

2.0 - 2006-02-07
  Complete rewrite.
  No longer moves the cursor around.
    This means that:
    - The jumplist is no longer affected.
    - No more shifting positions on horizontally scrolled windows.
  Added support for highlighting the pair that matches the character under the
    cursor.
  Added support for toggling ShowPairs on or off.
  Added a help file. HelpExtractor by Charles E. Campbell is used to install.

1.1 - 2003-04-27
   Fixed the fileformat so it doesn't include ^M's.
   Fixed the highlighting so it works when 'fg' and 'bg' aren't yet defined.

1.0 - 2003-04-22
   First release.

vim:tw=78:ts=8:ft=help
