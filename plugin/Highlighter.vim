if exists("g:loaded_Highlighter")
	finish
endif

let g:loaded_Highlighter = 1

lua require("Highlighter").setup({ debug = false })
