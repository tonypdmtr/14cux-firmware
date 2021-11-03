--==============================================================================
-- Convert a Motorola S-record (S19) file to its binary equivalent
-- Written by <tonyp@acm.org>
-- The following two lines show a data and terminator line for a typical S-rec
-- S1062000160119A9
-- S9030000FC
--==============================================================================

--require 'init'
unpack = table.unpack or unpack
cc = table.concat                                 -- cc stands for ConCat
chr = string.char

--------------------------------------------------------------------------------
-- Expand tabs to spaces
--------------------------------------------------------------------------------

function string:expandtabs(width)
  if not self:match('\t') then return self end
  width = width or 10
  local ans = {}
  for c in (self..'\t'):gmatch('([^\t]-)\t') do
    ans[#ans+1] = c
    ans[#ans+1] = (' '):rep(width - (#c % width))
  end
  ans[#ans] = nil --remove the one tab we went too far
  return cc(ans)
end

--------------------------------------------------------------------------------
-- Returns an iterator to return single lines from multiline text
--------------------------------------------------------------------------------

function string:lines()
  if self:sub(-1) ~= '\n' then self = self .. '\n' end
  return self:gmatch('(.-)\n')          --return self:gsplit('\n')
end

--------------------------------------------------------------------------------

function string:boxed(lt,h,rt,v,rb,lb)  --print a string inside a box
  lt = lt or '+'                        --left top corner character
  rt = rt or lt or '+'                  --right top corner character
  h = h or '-'                          --horizontal line character
  v = v or '|'                          --vertical line character
  lb = lb or lt or '+'                  --left top corner character
  rb = rb or rt or '+'                  --right top corner character

  local indent, self = self:match('(%s*)(.+)') --separate possible leading blanks

  local maxlen = 0                      --maximum length
  for line in self:lines() do
    line = line:expandtabs()
    if #line > maxlen then maxlen = #line end
  end

  local ans = {}
  for line in self:lines() do
    line = line:expandtabs()
    ans[#ans+1] = v
    ans[#ans+1] = ' '
    ans[#ans+1] = line
    ans[#ans+1] = (' '):rep(maxlen-#line+1)
    ans[#ans+1] = v
    ans[#ans+1] = '\n'
  end

  return cc( {                                    --return a single string with ...
    indent, lt, h:rep(maxlen+2), rt,'\n',         --top line
    indent, cc(ans),                              --message
    indent, lb, h:rep(maxlen+2), rb,              --bottom line
    })
end

--------------------------------------------------------------------------------
-- Command-line parameter related
--------------------------------------------------------------------------------

function united_parms(t)
  assert(type(t) == 'table','Table expected')
  local ans = {}
  for _,parm in ipairs(t) do
    if parm:sub(1,1) ~= '-' then ans[#ans+1] = parm end
  end
  return cc(ans,',')
end

--------------------------------------------------------------------------------

function run(cmd,debug)
  debug = debug == nil
  assert(type(cmd) == 'string','cmd should be the string of the command to run')
  if debug then print('Running...',cmd) end
  local f = io.popen(cmd)
  local ans = f:read('*a')
  f:close()
  return ans
end

--------------------------------------------------------------------------------
-- Escape special pattern characters in string to be treated as simple characters
--------------------------------------------------------------------------------

MAGIC_CHARS_SET = '[()%%.[^$%]*+%-?]'

function escape_magic(s)
  if s == nil then return end
  return (s:gsub(MAGIC_CHARS_SET,'%%%1'))
end

--------------------------------------------------------------------------------

function qsort(t,f,makecopy)            --t=table, optional comparison function, option make-copy boolean
  --extracted from Programming Pearls, page 110
  f = f or function(x,y) return x < y end  --default comparison function
  makecopy = makecopy or false          --default is to sort in-place
  assert(type(t) == 'table','Expected table as 1st parm')
  assert(type(f) == 'function','Expected compare function(x,y) as 2nd parm')
  assert(type(makecopy) == 'boolean','Boolean expected')
  if makecopy then t = copy(t) end
  local function sort(l,u)              --l=lower, u=upper
    if l<u then
     local m=math.random(u-(l-1))+l-1   -- choose a random pivot in range l..u
     t[l],t[m]=t[m],t[l]                -- swap pivot to first position
     local temp=t[l]                    -- pivot value
     m=l
     local i=l+1
     while i<=u do
       -- invariant: t[l+1..m] < temp <= t[m+1..i-1]
       if f(t[i],temp) then
         m=m+1
         t[m],t[i]=t[i],t[m]            -- swap t[i] and t[m]
       end
       i=i+1
     end
     t[l],t[m]=t[m],t[l]                -- swap pivot to a valid place
     -- t[l+1..m-1] < t[m] <= t[m+1..u]
     sort(l,m-1)
     sort(m+1,u)
    end
  end
  sort(1,#t)
  return t
end

--------------------------------------------------------------------------------
-- Returns iterator to split string on given delimiter (multi-space by default)
--------------------------------------------------------------------------------

function string:gsplit(delimiter)
  if delimiter == nil then return self:gmatch '%S+' end --default delimiter is any number of spaces
  if delimiter == '' then return self:gmatch '.' end --each character separately
  if type(delimiter) == 'number' then   --break string in equal-size chunks
    local index = 1
    local ans
    return function()
             ans = self:sub(index,index+delimiter-1)
             if ans ~= '' then
               index = index + delimiter
               return ans
             end
           end
  end
  if self:sub(-#delimiter) ~= delimiter then self = self .. delimiter end
  return self:gmatch('(.-)'..escape_magic(delimiter))
end

--------------------------------------------------------------------------------
-- Split a string on the given delimiter (multi-space by default)
--------------------------------------------------------------------------------

function string:split(delimiter,tabled)
  tabled = tabled or false              --default is unpacked
  local ans = {}
  for item in self:gsplit(delimiter) do
    ans[#ans+1] = item
  end
  if tabled then return ans end
  return unpack(ans)
end

--------------------------------------------------------------------------------
-- Path/File exists

function file_exists(path)
  if path == nil then return end
  local f = io.open(path)
  if f == nil then return end
  f:close()
  return path
end

--------------------------------------------------------------------------------
-- File related
--------------------------------------------------------------------------------

function filename_extension(filename,extension)
  --return filename but with given extension
  if filename == nil then return end
  extension = extension or ''           --assume no extension
  return (filename:gsub('([^%.]+).*','%1'..extension))
end

--------------------------------------------------------------------------------

function filename_default_extension(filename,extension)
  --return filename but with given extension ONLY if no extension is in filename
  if filename == nil then return end
  if filename:match('^[^%.]+$') then    --if no extension in original
    return filename_extension(filename,extension)
  else
    return filename
  end
end

--------------------------------------------------------------------------------
-- File related additions
--------------------------------------------------------------------------------

function filelist(filemasks,recursive) --separate masks with comma if needed
  recursive = recursive or false
  filemasks = filemasks or '*'
  if filemasks == '.' then filemasks = '*' end
  filemasks = filemasks:gsub('\\','/')
  if filemasks:sub(1,1) == '@' then
    local ans = {}
    for filemask in io.lines(filemasks:sub(2)) do
      ans[#ans+1] = filemask
    end
    filemasks = cc(ans,',')
  end
  local s,ans,path,last_path = '','','',''
  for file in filemasks:gsplit(',') do
    if not file:match('^%s*$') then
      path,file = file:match('^(.-)([^/\\]-)$')
      if file == '' then file = '*' end
      path = (path or ''):gsub('/','\\')
      if path ~= '' then last_path = path end
      if file:match('^%.') then file = '*'..file end
      if recursive then
        s = 'for /r '..last_path..' %i in ($LIST$) do @echo %i'
      else
        s = 'for %i in ($LIST$) do @echo %i'
        file = last_path .. file
      end
      file = file:gsub('%%','%%%%')
      s = s:gsub('%$LIST%$',file)
      ans = ans .. run(s,false)
    end
  end
  --return ans:gsplit('\n')             --this will not filter lines at all
  ans = ans:split('\n',true)            --convert text to a table
  local key,line
  return function()
           repeat
             key,line = next(ans,key)
             if key == nil then return end
             if line:match('%S+') and file_exists(line) then
               return line              --only non-blank lines and existing filenames
             end
           until false
         end
end

--------------------------------------------------------------------------------

local option = {
  talker = false,   --prepend $FF for HC11 talker and make .BAT
  subdirs = false,  --when true process subdirectories also
  debug = false,    --when true show S19 lines as processed
}

--------------------------------------------------------------------------------

local batchfile_text = [[
@ECHO OFF
REM Created by EXBIN by Tony G. Papadimitriou [tonyp@acm.org]
if "%1"=="2" goto CONTINUE
if "%1"=="1" goto CONTINUE
ECHO Usage: $FILE$.BAT COMPORT [F] (eg., $FILE$.BAT 1 or $FILE$.BAT 2)
ECHO        Optional F used for 16MHz (4MHz bus) systems
ECHO This batch file will send the binary file $FILE$.BIN to COM1 or COM2
GOTO EXIT
:CONTINUE
ECHO Set MCU in bootstrap mode and then ...
PAUSE
if "%2"=="F" goto FAST
if "%2"=="f" goto FAST
MODE COM%1 BAUD=1200 PARITY=N DATA=8 STOP=1
goto COPY
:FAST
MODE COM%1 BAUD=2400 PARITY=N DATA=8 STOP=1
:COPY
COPY /B $FILE$.BIN COM%1
:EXIT
]]

--------------------------------------------------------------------------------

local
function comparator(x,y)
  local rt = x:upper():sub(1,2)
  if rt == 'S1' then
    return x:sub(2,2)..'0000'..x:sub(5,8) < y:sub(2,2)..'0000'..y:sub(5,8)
  elseif rt == 'S2' then
    return x:sub(2,2)..'00'..x:sub(5,10) < y:sub(2,2)..'00'..y:sub(5,10)
  elseif rt == 'S3' then
    return x:sub(2,2)..x:sub(5,12) < y:sub(2,2)..y:sub(5,12)
  end
end

--------------------------------------------------------------------------------

local
function convert(filename)
  local data = {}
  for line in io.lines(filename) do
    if line:match('[Ss][123]%x+') then --filter out non-S1/S2/S3 records
      data[ #data+1 ] = line
    end
  end

  ----------------------------
  -- sort the lines by address
  ----------------------------

  data = qsort(data,comparator)

  local old_address = nil

  -----------------------------
  -- write out the sorted lines
  -----------------------------

  f = io.open(filename_extension(filename,'.bin'),'wb')
  if option.talker then
    f:write(chr(0xFF))
    local bf = io.open(filename_extension(filename,'.bat'),'wb')
    assert(bf ~= nil,'Could not open BAT file')
    bf:write((batchfile_text:gsub('%$FILE%$',filename_extension(filename):upper())))
    if option.debug then
      print((batchfile_text:gsub('%$FILE%$',filename_extension(filename):upper())))
    end
    bf:close()
  end
  for _,line in ipairs(data) do
    if option.debug then print(line) end
    local address
    local crc
    local my_crc
    if line:upper():sub(1,2) == 'S1' then
      address = tonumber('0x'..line:sub(5,8))
      crc = tonumber('0x'..line:sub(-2))
      my_crc = tonumber('0x'..line:sub(3,4))+
               tonumber('0x'..line:sub(5,6))+
               tonumber('0x'..line:sub(7,8))
      line = line:sub(9,-3)             --isolate data bytes
    elseif line:upper():sub(1,2) == 'S2' then
      address = tonumber('0x'..line:sub(5,10))
      crc = tonumber('0x'..line:sub(-2))
      my_crc = tonumber('0x'..line:sub(3,4))+
               tonumber('0x'..line:sub(5,6))+
               tonumber('0x'..line:sub(7,8))+
               tonumber('0x'..line:sub(9,10))
      line = line:sub(11,-3)            --isolate data bytes
    elseif line:upper():sub(1,2) == 'S3' then
      address = tonumber('0x'..line:sub(5,12))
      crc = tonumber('0x'..line:sub(-2))
      my_crc = tonumber('0x'..line:sub(3,4))+
               tonumber('0x'..line:sub(5,6))+
               tonumber('0x'..line:sub(7,8))+
               tonumber('0x'..line:sub(9,10))+
               tonumber('0x'..line:sub(11,12))
      line = line:sub(13,-3)            --isolate data bytes
    end
    if old_address ~= nil and old_address ~= address then
      for i = old_address,address-1 do
        --io.write(string.format('0x%04X: 0x%02X\n',i,0xFF))          --DEBUG
        f:write(chr(0xFF))
      end
    end
    for byte in line:gmatch('%x%x') do
      byte = tonumber('0x'..byte)
      my_crc = my_crc + byte
      --io.write(string.format('0x%04X: 0x%02X\n',address,byte))      --DEBUG
      f:write(chr(byte))
      address = address + 1
    end
    old_address = address
    my_crc = (my_crc ~ -1) % 256
    if my_crc ~= crc then
      print(string.format('CRC failure at 0x%X (found 0x%02X, should be 0x%02X)',address,my_crc,crc))
    end
  end
  f:close()
end

--------------------------------------------------------------------------------

local
function dotted_line(len)
  print(('-'):rep(len))
end

--------------------------------------------------------------------------------

if arg[1] == nil then
  print('Usage: exbin <filename> ...')
  print('       Converts S19 file(s) to binary image(s)')
  print('       Options:')
  print('         -t -- create talker')
  print('         -s -- process subdirectories')
  print('         -d -- debug mode (e.g., show S19 content)')
  return
end

for _,opt in ipairs(arg) do
  if opt:sub(1,1) == '-' then
    opt = opt:sub(2):lower()
    if opt == 't' then option.talker = true
    elseif opt == 's' then option.subdirs = true
    elseif opt == 'd' then option.debug = true
    end
  end
end

for filename in filelist(united_parms(arg),option.subdirs) do
  if option.debug then
    print(filename:boxed())
  else
    print('Processing ' .. filename)
  end
  convert(filename_default_extension(filename,'.s19'))
end

print('Done!')
