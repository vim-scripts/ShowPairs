" ==============================================================================
" Name:          ShowPairs
" Description:   Highlights the pair surrounding the current cursor location.
" Author:        Anthony Kruize <trandor@labyrinth.net.au>
" Version:       1.1
" Modified:      22 April 2003
" ChangeLog:     1.1 - Fixed the fileformat so it doesn't include ^M's.
"                      Fixed the highlighting so it works when 'fg' and 'bg'
"                      aren't yet defined.
"                1.0 - First release.
"
" Usage:         Copy this file into the plugin directory so it will be
"                automatically sourced.
"
" Configuration: ShowPairs uses the 'matchpairs' global option to determine
"                which pairs to highlight. To make ShowPairs highlight a
"                specific pair, simply add it to the 'matchpairs' option.
"                For more information see  :help matchpairs
"
"                ShowPairs uses the 'cursorhold' autocommand to trigger it's
"                highlight check. This is triggered every 'updatetime'
"                milliseconds(default 4000).  If this is too slow, set
"                'updatetime' to a lower value.
"                For more information see  :help updatetime
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showpairs" )
	finish
endif
let loaded_showpairs = 1

" Highlighting: By default we'll simply bold the pairs to make them stand out.
"hi default ShowPairsHL ctermfg=fg ctermbg=bg cterm=bold guifg=fg guibg=bg gui=bold
hi default ShowPairsHL cterm=bold gui=bold

" AutoCommands
aug ShowPairs
	au!
	autocmd CursorHold * call s:ShowPairs()
aug END

" Function: ShowPairs()
" Description: This function highlights the pair that the cursor is
" currently inside, while hopefully keeping the cursor where it is.
fun! s:ShowPairs()
	let cln = line(".")
	let ccol = virtcol(".")
	norm! H
	let fln = line(".")
	exe "normal! ".cln."G".ccol."|"

	match none

	let pairs = substitute(&mps,",","","g")
	let ps = "[".substitute(pairs,":.","","g")."]"
	let pe = substitute(pairs,".:","","g")
	if( match(pe,"]") > 0 )
		let pe = "]".substitute(pe,"]","","")
	endif
	let pe = "[".pe."]"

	let fbln = searchpair(ps,"",pe,"bW")
	let fbcol = virtcol(".")
	let lbln = searchpair(ps,"",pe,"W")
	let lbcol = virtcol(".")
	exe 'match ShowPairsHL /\%'.fbln.'l\%'.fbcol.'v\|\%'.lbln.'l\%'.lbcol.'v/'

	exe "norm! ".fln."G"
	norm! zt
	exe "norm! ".cln."G".ccol."|"
endf

" vim:ts=4:sw=4:noet
