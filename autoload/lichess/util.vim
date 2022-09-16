let s:script_path = expand("<sfile>:p:h")

fun! lichess#util#plugin_path() abort
    let plugin_path = split(s:script_path, '/')[:-3]
    return '/' . join(plugin_path, '/')
endfun

fun! lichess#util#log_msg(msg, level)
    let plugin_path = lichess#util#plugin_path()
python3 << EOF
import os, sys, vim
plugin_path = vim.eval('plugin_path')
sys.path.append(os.path.join(plugin_path, 'python'))

from util import log_message
log_message(vim.eval('a:msg'), int(vim.eval('a:level')))
EOF
endfun
