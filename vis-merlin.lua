local posix = require "posix"
local unistd = require "posix.unistd"
local sys_wait = require "posix.sys.wait"

local json = require ("dkjson")

local initMsg = {
	"tell",
	"start",
	"end",
	"let f x = x let () = ()"
}

local followUpMsg = {
	"return",
	"'a -> 'a"
}


local merlin_stdout_r, merlin_stdout_w = unistd.pipe ()
assert(merlin_stdout_r ~= nil, merlin_stdout_w)
local merlin_stderr_r, merlin_stderr_w = unistd.pipe ()
assert(merlin_stderr_r ~= nil, merlin_stderr_w)

local merlin_pid, errmsg = unistd.fork ()
assert(merlin_pid ~= nil, errmsg)

if merlin_pid == 0 then
	-- MERLIN PROCESS
	unistd.close(merlin_stdout_w)
	unistd.close(merlin_stderr_w)

	unistd.dup2(merlin_stdout_r, unistd.STDOUT_FILENO)
	unistd.dup2(merlin_stderr_r, unistd.STDERR_FILENO)

	-- Exec() a subprocess here instead if you like --
	posix.exec("ocamlmerlin")
	exit(2)
end

unistd.write(merlin_stdout_w, json.encode(initMsg) .. "\n")
io.flush()
local outs, errmsg = unistd.read (merlin_stdout_r, 1024)
io.flush()
assert (outs ~= nil, errmsg)
print ("STDOUT:", outs)

unistd.write(merlin_stdout_w, json.encode(followUpMsg) .. "\n")
io.flush()
local outs, errmsg = unistd.read (merlin_stdout_r, 1024)
io.flush()
assert (outs ~= nil, errmsg)
print ("STDOUT:", outs)

local errs, errmsg = unistd.read (merlin_stderr_r, 1024)
assert (errs ~= nil, errmsg)
print ("STDERR:", errs)

local merlin_pid, reason, status = sys_wait.wait (pid)
assert (merlin_pid ~= nil, reason)
print ("child " .. reason, status)

