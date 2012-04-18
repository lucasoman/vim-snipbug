" SNIP BUG
" Easily and iteratively test snippets of code within a larger app.
"
" The workspace involves four windows:
" 1. The header code to be prepended to the test code.
" 2. The footer code to be postpended to the test code.
" 3. The output of the code execution.
" 4. The source code file.
"
" After opening the source code file, simply call :SnipBug to open the rest of
" the windows, or visually select the lines you want to test and call
" :SnipBugDebug.
"
" Example:
"
" If you wanted to test the following PHP code:
"
" foreach ($foo as $bar) {
"   echo $bar;
" }
"
" Then you may put the following in the header window:
"
" <?php
" $foo = array(1,2,3);
"
" And the following in the footer window:
"
" echo 'done!';
" ?>
"
" Then select the foreach loop in visual line mode and call :SnipBugDebug. The
" output of the test will appear in the output window.
"
" Modify the selected lines as you see fit and call :SnipBugRepeat to execute
" the same lines again.
"
" When finished, call :SnipBugStop to close all windows but the source code
" window.
"
" Commands:
"
" :SnipBug - create the Snip Bug workspace
" :SnipBugDebug - debug visually selected lines and create workspace if it
" doesn't exist yet
" :SnipBugStop - close the workspace
" :SnipBugRepeat - repeat the execution on the same lines of code
"
" Configuration:
"
" g:sb_tempfile - location of temporary code file for test execution.
" g:sb_languages - dictionary of filetypes and the command to execute a file of
" that type: 'filetype':'execution command'

" Configuration:
let g:sb_tempfile = '/home/lucas/temp.sb'
let g:sb_languages = {
	\ 'php':{'command':'php'},
	\ 'sh':{'command':'sh'}
	\ }

" Don't modify anything after this.

com! -nargs=0 SnipBug :call Sb_DebuggerSetup(bufname('%'))
com! -nargs=0 -range SnipBugDebug :call Sb_Debug(<count>)
com! -nargs=0 SnipBugStop :call Sb_StopDebugger()
com! -nargs=0 SnipBugRepeat :call Sb_Repeat()

fun! Sb_Debug(end)
	let t:laststart = line('.')
	let t:lastend = t:laststart + a:end
	let t:lastfile = bufname('%')

	call Sb_Repeat()
endfun

fun! Sb_DebugRun(file,start,end)
	if (gettabvar(tabpagenr(),'setup') != 1)
		call Sb_DebuggerSetup(a:file)
	end

	if (a:end > 0)
		let config = Sb_GetFiletypeConfig(t:type)
		let filename = a:file
		let codelines = getbufline(bufnr(l:filename),a:start,a:end)
		let headlines = getbufline(bufnr(l:filename.'-head'),1,'$')
		let footlines = getbufline(bufnr(l:filename.'-foot'),1,'$')
		let total = l:headlines + l:codelines + l:footlines

		call writefile(l:total,g:sb_tempfile)
		let t:curwin = winnr()
		exe t:outwin.'wincmd w'
		normal ggdG
		let command = l:config['command']
		exec 'r!'.l:command.' '.g:sb_tempfile
		normal ggdd
		exe t:curwin.'wincmd w'
		normal gv
	end
endfun

fun! Sb_Repeat()
	call Sb_DebugRun(t:lastfile,t:laststart,t:lastend)
endfun

fun! Sb_DebuggerSetup(file)
	let filename = bufname(a:file)
	let t:type = &ft

	exe 'vnew '.l:filename.'-out'
	setl buftype=nofile
	let t:outwin = 3

	exe 'new '.l:filename.'-foot'
	exe 'set filetype='.t:type
	setl buftype=nofile
	let t:footwin = 2

	exe 'new '.l:filename.'-head'
	exe 'set filetype='.t:type
	setl buftype=nofile
	let t:headwin = 1

	let t:setup = 1
	exe winnr('$').'wincmd w'
endfun

fun! Sb_StopDebugger()
	let t:setup = 0

	exe '1wincmd w'
	q
	q
	q
endfun

fun! Sb_GetFiletypeConfig(type)
	return g:sb_languages[a:type]
endfun
