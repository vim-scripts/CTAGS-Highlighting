" ctags_highlighting
"   Author:  A. S. Budden
"## Date::   7th April 2011          ##
"## RevTag:: r458                    ##

if &cp || exists("g:loaded_ctags_highlighting")
	finish
endif
let g:loaded_ctags_highlighting = 1

let s:CTagsHighlighterVersion = "## RevTag:: r458 ##"
let s:CTagsHighlighterVersion = substitute(s:CTagsHighlighterVersion, '[#]\{2} RevTag[:]\{2} \(r\d\+\) *[#]\{2}', '\1', '')

if !exists('g:VIMFILESDIR')
	let g:VIMFILESDIR = fnamemodify(globpath(&rtp, 'mktypes.py'), ':p:h')
endif

let g:DBG_None        = 0
let g:DBG_Critical    = 1
let g:DBG_Error       = 2
let g:DBG_Warning     = 3
let g:DBG_Status      = 4
let g:DBG_Information = 5

if !exists('g:CTagsHighlighterDebug')
	let g:CTagsHighlighterDebug = g:DBG_None
endif

func! s:GetOption(name, default)
	let opt = a:default
	if exists('g:' . a:name)
		exe 'let opt = g:' . a:name
	endif
	if exists('b:' . a:name)
		exe 'let opt = b:' . a:name
	endif
	return opt
endfunction

" These should only be included if editing a wx or qt file
" They should also be updated to include all functions etc, not just
" typedefs
let g:wxTypesFile = escape(globpath(&rtp, "types_wx.vim"), '\,')
let g:qtTypesFile = escape(globpath(&rtp, "types_qt4.vim"), '\,')
let g:wxPyTypesFile = escape(globpath(&rtp, "types_wxpy.vim"), '\,')
let g:jdkTypesFile = escape(globpath(&rtp, "types_jdk.vim"), '\,')
let g:androidTypesFile = escape(globpath(&rtp, "types_android.vim"), '\,')

" These should only be included if editing a wx or qt file
let g:wxTagsFile = escape(globpath(&rtp, 'tags_wx'), ' \,')
let g:qtTagsFile = escape(globpath(&rtp, 'tags_qt4'), ' \,')
let g:wxPyTagsFile = escape(globpath(&rtp, 'tags_wxpy'), ' \,')

" Update types & tags - called with a ! recurses
command! -bang -bar UpdateTypesFile silent call UpdateTypesFile(<bang>0, 0) | 
			\ let s:SavedTabNr = tabpagenr() |
			\ let s:SavedWinNr = winnr() |
			\ silent tabdo windo call ReadTypesAutoDetect() |
			\ silent exe 'tabn ' . s:SavedTabNr |
			\ silent exe s:SavedWinNr . "wincmd w"

command! -bang -bar UpdateTypesFileOnly silent call UpdateTypesFile(<bang>0, 1) | 
			\ let s:SavedTabNr = tabpagenr() |
			\ let s:SavedWinNr = winnr() |
			\ silent tabdo windo call ReadTypesAutoDetect() |
			\ silent exe 'tabn ' . s:SavedTabNr |
			\ silent exe s:SavedWinNr . "wincmd w"

" load the types_*.vim highlighting file, if it exists
autocmd BufRead,BufNewFile *.[ch]   call ReadTypes('c')
autocmd BufRead,BufNewFile *.[ch]pp call ReadTypes('c')
autocmd BufRead,BufNewFile *.p[lm]  call ReadTypes('pl')
autocmd BufRead,BufNewFile *.java   call ReadTypes('java')
autocmd BufRead,BufNewFile *.py     call ReadTypes('py')
autocmd BufRead,BufNewFile *.pyw    call ReadTypes('py')
autocmd BufRead,BufNewFile *.rb     call ReadTypes('ruby')
autocmd BufRead,BufNewFile *.vhd*   call ReadTypes('vhdl')
autocmd BufRead,BufNewFile *.php    call ReadTypes('php')
autocmd BufRead,BufNewFile *.cs     call ReadTypes('cs')

command! ReadTypes call ReadTypesAutoDetect()

function! ReadTypesAutoDetect()
	let extension = expand('%:e')
	let extensionLookup = 
				\ {
				\     '\(c\|cc\|cpp\|h\|hpp\|cxx\|hxx\)' : "c",
				\     'p[lm]'                            : "pl",
				\     'java'                             : "java",
				\     'pyw\?'                            : "py",
				\     'rb'                               : "ruby",
				\     'cs'                               : "cs",
				\     'php'                              : "php",
				\     'vhdl\?'                           : "vhdl",
				\ }

	call s:Debug_Print(g:DBG_Information, "Detecting types for extension '" . extension . "'")
	for key in keys(extensionLookup)
		let regex = '^' . key . '$'
		if extension =~ regex
			call s:Debug_Print(g:DBG_Information, "Loading types for extension '" . extensionLookup[key] . "'")
			call ReadTypes(extensionLookup[key])
			continue
		endif
	endfor
endfunction

function! ReadTypes(suffix)
	let savedView = winsaveview()

	let file = '<afile>'
	if len(expand(file)) == 0
		let file = '%'
	endif

	if exists('b:NoTypeParsing')
		call s:Debug_Print(g:DBG_Information, "Type file parsing disabled")
		return
	endif
	if exists('g:TypeParsingSkipList')
		let basename = expand(file . ':p:t')
		let fullname = expand(file . ':p')
		if index(g:TypeParsingSkipList, basename) != -1
			call s:Debug_Print(g:DBG_Information, "Skipping file due to basename match")
			return
		endif
		if index(g:TypeParsingSkipList, fullname) != -1
			call s:Debug_Print(g:DBG_Information, "Skipping file due to fullname match")
			return
		endif
	endif
	let fname = expand(file . ':p:h') . '/' . s:GetOption('TypesPrefix', 'types') . '_' . a:suffix . '.vim'
	call s:Debug_Print(g:DBG_Information, "Checking for file " . fname)
	if filereadable(fname)
		call s:Debug_Print(g:DBG_Information, "Found")
		exe 'so ' . fname
	endif
	let fname = expand(file . ':p:h:h') . '/' . s:GetOption('TypesPrefix', 'types') . '_' . a:suffix . '.vim'
	call s:Debug_Print(g:DBG_Information, "Checking for file " . fname)
	if filereadable(fname)
		call s:Debug_Print(g:DBG_Information, "Found")
		exe 'so ' . fname
	endif
	let fname = s:GetOption('TypesPrefix', 'types') . '_' . a:suffix . '.vim'
	call s:Debug_Print(g:DBG_Information, "Checking for file " . fname)
	if filereadable(fname)
		call s:Debug_Print(g:DBG_Information, "Found")
		exe 'so ' . fname
	endif

	" Open default source files
	if index(['cc', 'cpp', 'h', 'hpp'], expand(file . ':e')) != -1
		call s:Debug_Print(g:DBG_Information, 'C++ source file, checking for wx/Qt')
		" This is a C++ source file
		call cursor(1,1)
		if search('^\s*#include\s\+<wx/', 'nc', 30)
			call s:Debug_Print(g:DBG_Information, 'WxWidgets Source file - checking ' . g:wxTypesFile . '"')
			if filereadable(g:wxTypesFile)
				call s:Debug_Print(g:DBG_Information, 'Loading wx types')
				execute 'so ' . g:wxTypesFile
			endif
			if filereadable(g:wxTagsFile)
				execute 'setlocal tags+=' . g:wxTagsFile
			endif
		endif

		call cursor(1,1)
		if search('\c^\s*#include\s\+<q', 'nc', 30)
			call s:Debug_Print(g:DBG_Information, 'Qt Source file - checking "' . g:qtTypesFile . '"')
			if filereadable(g:qtTypesFile)
				call s:Debug_Print(g:DBG_Information, 'Loading Qt4 types')
				execute 'so ' . g:qtTypesFile
			endif
			if filereadable(g:qtTagsFile)
				execute 'setlocal tags+=' . g:qtTagsFile
			endif
		else
		endif
	elseif index(['py', 'pyw'], expand(file . ':e')) != -1
		" This is a python source file
		call s:Debug_Print(g:DBG_Information, 'Python source file, checking for wx')

		call cursor(1,1)
		if search('^\s*import\s\+wx', 'nc', 30)
			call s:Debug_Print(g:DBG_Information, 'wxPython Source file - checking "' . g:wxPyTypesFile . '"')
			if filereadable(g:wxPyTypesFile)
				call s:Debug_Print(g:DBG_Information, 'Loading wxpython types')
				execute 'so ' . g:wxPyTypesFile
			endif
			if filereadable(g:wxPyTagsFile)
				execute 'setlocal tags+=' . g:wxPyTagsFile
			endif
		endif
	elseif index(['java',], expand(file . ':e')) != -1
		" This is a java source file
		call s:Debug_Print(g:DBG_Information, 'Java Source file - checking "' . g:jdkTypesFile . '"')
		if filereadable(g:jdkTypesFile)
			call s:Debug_Print(g:DBG_Information, 'Loading JDK types')
			execute 'so ' . g:jdkTypesFile
		endif
		call cursor(1,1)
		if search('^\s*import\s\+android\.', 'nc', 30)
			call s:Debug_Print(g:DBG_Information, 'Android Source file - checking "' . g:androidTypesFile . '"')
			if filereadable(g:androidTypesFile)
				call s:Debug_Print(g:DBG_Information, 'Loading Android types')
				execute 'so ' . g:androidTypesFile
			endif
		endif
	endif

	" Restore the view
	call winrestview(savedView)
endfunction

func! s:Debug_Print(level, message)
	if g:CTagsHighlighterDebug >= a:level
		echomsg a:message
	endif
endfunc

func! s:FindExePath(file)
	if has("win32")
		let short_file = fnamemodify(a:file . '.exe', ':p:t')
		let path = substitute($PATH, '\\\?;', ',', 'g')

		call s:Debug_Print(g:DBG_Status, "Looking for " . short_file . " in " . path)

		let file_exe_list = split(globpath(path, short_file), '\n')
		if len(file_exe_list) > 0
			call s:Debug_Print(g:DBG_Status, "Success.")
			let file_exe = file_exe_list[0]
		else
			call s:Debug_Print(g:DBG_Status, "Not found.")
			let file_exe = ''
		endif

		" If file is not in the path, look for it in vimfiles/
		if !filereadable(file_exe)
			call s:Debug_Print(g:DBG_Status, "Looking for " . a:file . " in " . &rtp)
			let file_exe_list = split(globpath(&rtp, a:file . '.exe'), '\n')
			if len(file_exe_list) > 0
				call s:Debug_Print(g:DBG_Status, "Success.")
				let file_exe = file_exe_list[0]
			else
				call s:Debug_Print(g:DBG_Status, "Not found.")
			endif
		endif

		if filereadable(file_exe)
			call s:Debug_Print(g:DBG_Status, "Success.")
			let file_path = shellescape(fnamemodify(file_exe, ':p:h'))
		else
			call s:Debug_Print(g:DBG_Critical, "Could not find " . short_file)
			throw "Cannot find file " . short_file
		endif
	else
		let path = substitute($PATH, ':', ',', 'g')
		if has("win32unix")
			let short_file = fnamemodify(a:file . '.exe', ':p:t')
		else
			let short_file = fnamemodify(a:file, ':p:t')
		endif

		call s:Debug_Print(g:DBG_Status, "Looking for " . short_file . " in " . path)

		let file_exe_list = split(globpath(path, short_file), '\n')

		if len(file_exe_list) > 0
			call s:Debug_Print(g:DBG_Status, "Success.")
			let file_exe = file_exe_list[0]
		else
			call s:Debug_Print(g:DBG_Status, "Not found.")
			let file_exe = ''
		endif

		if filereadable(file_exe)
			call s:Debug_Print(g:DBG_Status, "Success.")
			let file_path = fnamemodify(file_exe, ':p:h')
		else
			call s:Debug_Print(g:DBG_Critical, "Could not find " . short_file)
			throw "Cannot find file " . short_file
		endif
	endif

	let file_path = substitute(file_path, '\\', '/', 'g')

	return file_path
endfunc

func! UpdateTypesFile(recurse, skiptags)
	let s:vrc = globpath(&rtp, "mktypes.py")

	call s:Debug_Print(g:DBG_Status, "Starting UpdateTypesFile revision " . s:CTagsHighlighterVersion)

	if type(s:vrc) == type("")
		let mktypes_py_file = s:vrc
	elseif type(s:vrc) == type([])
		let mktypes_py_file = s:vrc[0]
	endif

	let sysroot = 'python ' . shellescape(mktypes_py_file)
	let syscmd = ' --ctags-dir='

	let ctags_path = s:FindExePath('ctags')

	let syscmd .= ctags_path
	
	if exists('b:TypesFileRecurse')
		if b:TypesFileRecurse == 1
			let syscmd .= ' -r'
		endif
	else
		if a:recurse == 1
			let syscmd .= ' -r'
		endif
	endif

	if exists('b:TypesFileLanguages')
		for lang in b:TypesFileLanguages
			let syscmd .= ' --include-language=' . lang
		endfor
	endif

	let TypesFileIncludeSynMatches = s:GetOption('TypesFileIncludeSynMatches', 0)
	if TypesFileIncludeSynMatches == 1
		let syscmd .= ' --include-invalid-keywords-as-matches'
	endif

	let TypeFileSkipVimKeywords = s:GetOption('TypesFileSkipVimKeywords', 0)
	if TypeFileSkipVimKeywords == 1
		let syscmd .= ' --exclude-vim-keywords'
	endif

	let TypesFileIncludeLocals = s:GetOption('TypesFileIncludeLocals', 1)
	if TypesFileIncludeLocals == 1
		let syscmd .= ' --include-locals'
	endif

	let TypesFileDoNotGenerateTags = s:GetOption('TypesFileDoNotGenerateTags', 0)
	if TypesFileDoNotGenerateTags == 1
		let syscmd .= ' --use-existing-tagfile'
	elseif a:skiptags == 1
		let syscmd .= ' --use-existing-tagfile'
	endif

	let syscmd .= ' --ctags-file ' . s:GetOption('TypesCTagsFile', 'tags')
	let syscmd .= ' --types-prefix ' . s:GetOption('TypesPrefix', 'types')

	let CheckForCScopeFiles = s:GetOption('CheckForCScopeFiles', 0)
	if CheckForCScopeFiles == 1
		if cscope_connection()
			" Kill all existing cscope connections so that the database can be
			" rebuilt.  Because we run cscope in the background (from python)
			" we can't just re-add the cscope database as it might not have
			" finished yet.  Otherwise, we'd parse the output of 'cs show'
			" and re-add the database at the end of the function.
			cs kill -1
		endif
		let syscmd .= ' --build-cscopedb-if-cscope-file-exists'
		let syscmd .= ' --cscope-dir=' 
		let cscope_path = s:FindExePath('extra_source/cscope_win/cscope')
		let syscmd .= cscope_path
	endif

	let sysoutput = system(sysroot . syscmd) 
	echo sysroot . syscmd
	if sysoutput =~ 'python.*is not recognized as an internal or external command'
		let sysroot = g:VIMFILESDIR . '/extra_source/mktypes/dist/mktypes.exe'
		let sysoutput = sysoutput . "\nUsing compiled mktypes\n" . system(sysroot . syscmd)
	endif

	echo sysoutput

	if g:CTagsHighlighterDebug >= g:DBG_None
		echomsg sysoutput
		messages
	endif

	" There should be a try catch endtry
	" above, with the fall-back using the
	" exe on windows or the full system('python') etc
	" on Linux

endfunc

let tagnames = 
			\ [
			\ 		'CTagsAnchor',
			\ 		'CTagsAutoCommand',
			\ 		'CTagsBlockData',
			\ 		'CTagsClass',
			\ 		'CTagsCommand',
			\ 		'CTagsCommonBlocks',
			\ 		'CTagsComponent',
			\ 		'CTagsConstant',
			\ 		'CTagsCursor',
			\ 		'CTagsData',
			\ 		'CTagsDefinedName',
			\ 		'CTagsDomain',
			\ 		'CTagsEntity',
			\ 		'CTagsEntryPoint',
			\ 		'CTagsEnumeration',
			\ 		'CTagsEnumerationName',
			\ 		'CTagsEnumerationValue',
			\ 		'CTagsEnumerator',
			\ 		'CTagsEnumeratorName',
			\ 		'CTagsEvent',
			\ 		'CTagsException',
			\ 		'CTagsExtern',
			\ 		'CTagsFeature',
			\ 		'CTagsField',
			\ 		'CTagsFileDescription',
			\ 		'CTagsFormat',
			\ 		'CTagsFragment',
			\ 		'CTagsFunction',
			\ 		'CTagsFunctionObject',
			\ 		'CTagsGlobalConstant',
			\ 		'CTagsGlobalVariable',
			\ 		'CTagsGroupItem',
			\ 		'CTagsIndex',
			\ 		'CTagsInterface',
			\ 		'CTagsInterfaceComponent',
			\ 		'CTagsLabel',
			\ 		'CTagsLocalVariable',
			\ 		'CTagsMacro',
			\ 		'CTagsMap',
			\ 		'CTagsMember',
			\ 		'CTagsMethod',
			\ 		'CTagsModule',
			\ 		'CTagsNamelist',
			\ 		'CTagsNamespace',
			\ 		'CTagsNetType',
			\ 		'CTagsPackage',
			\ 		'CTagsParagraph',
			\ 		'CTagsPattern',
			\ 		'CTagsPort',
			\ 		'CTagsProgram',
			\ 		'CTagsProperty',
			\ 		'CTagsPrototype',
			\ 		'CTagsPublication',
			\ 		'CTagsRecord',
			\ 		'CTagsRegisterType',
			\ 		'CTagsSection',
			\ 		'CTagsService',
			\ 		'CTagsSet',
			\ 		'CTagsSignature',
			\ 		'CTagsSingleton',
			\ 		'CTagsSlot',
			\ 		'CTagsStructure',
			\ 		'CTagsSubroutine',
			\ 		'CTagsSynonym',
			\ 		'CTagsTable',
			\ 		'CTagsTask',
			\ 		'CTagsTrigger',
			\ 		'CTagsType',
			\ 		'CTagsTypeComponent',
			\ 		'CTagsUnion',
			\ 		'CTagsVariable',
			\ 		'CTagsView',
			\ 		'CTagsVirtualPattern',
			\ ]

for tagname in tagnames
	let simplename = substitute(tagname, '^CTags', '', '')
	exe 'hi default link' tagname simplename
	exe 'hi default link' simplename 'Keyword'
endfor
