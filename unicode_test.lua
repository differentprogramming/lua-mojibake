--[[/* Common functions and includes for our test programs. */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <stdarg.h>

#include "mojibake.h"
--]]

local mojibake =  require 'mojibake'
local buf_index = mojibake.buf_index
local encode_char_into_buffer = mojibake.encode_char_into_buffer

local unicode_test;
--local lineno = 0;

local function check(cond, fn)
     if (not cond) then
--          error( {msg=string.format("line %d: ", unicode_test.lineno) .. string.format(...), code=1});
          print( string.format("line %d: ", unicode_test.lineno) .. string.format(fn()));
--          return false
         error()
   end
   return true
end

local function isspace(s)
  if not s then return false end
	return s==0x20 or (s>=9 and s<=13);
end
local function isxdigit(s)
  if not s then return false end
	return (s<=0x39 and s>=0x30) or (s<=0x46 and s>=0x41) or (s<=0x66 and s>=0x61);
end
--altered to be 1 based
local function skipspaces(buf, i)
    while (isspace(buf_index(buf,i))) do i=i+1 end
    return i
end

--[[ if buf points to a sequence of codepoints encoded as hexadecimal strings,
   separated by whitespace, and terminated by any character not in
   [0-9a-fA-F] or whitespace, then stores the corresponding utf8 string
   in dest, returning the number of bytes read from buf 
   
   buf can be a string or an array of single characters, since lua doesn't allow 
   mutable strings, we're using that as a convenient proxy for mutable strings
   the returned value is an array of characters, use table.concat() if you want 
   a regular string from it.
--]]
local function encode(dest, buf, buf_offset)
--  print('encode ' .. buf .. ' at ' .. buf_offset)
  local i = buf_offset;
  
  while true do 
          
    i = skipspaces(buf, i); --note offset by buf_offset relative to c version
    local j=i;
	  
	  while j<=#buf and isxdigit(buf_index(buf,j)) do j=j+1 end
    -- find end of hex input 
	       
    if (j == i) then --  no codepoint found
      --print('no codepoint at '.. j)
      -- table.insert(dest, '\x0'); -- NUL-terminate destination string 
      return i + 1;
    end
--	  print('hex from '..i .. ' to ' ..  j-1)
	  --extract hex number whether buf is a string or an array of single characters (as strings)
	  local c;
	  
    if type(buf) == 'string' then c=string.sub(buf,i,j-1) 
	  else 
      c={}
      for d=i,j-1 do table.insert(c,buf[d]) end
      c=table.concat(c)
    end
--    print('number is "'..c..'"')
	  c=tonumber(c,16) 
          --check(sscanf(buf + i, "%x", &c) == 1, "invalid hex input %s", buf+i);
    i = j; --/* skip to char after hex input */
    encode_char_into_buffer(dest,c);
  end
end

unicode_test = 
{ check=check, isspace=isspace, isxdigit=isxdigit, skipspaces=skipspaces, encode=encode, lineno=0 }

return unicode_test
