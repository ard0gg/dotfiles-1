
if has('win32')
	set gfn=Consolas:h12:cANSI
elseif has('mac')
	set gfn=Menlo:h12:cANSI
elseif has('unix')
	"set gfn=DejaVu\ Sans\ Mono:h12:cANSI
endif

" Hide toolbar by default
set guioptions-=m
set guioptions-=T

" Why does it open with GUI by default...?
let g:nerdtree_tabs_open_on_gui_startup=0

" I like the degraded color scheme
let g:solarized_degrade=1
