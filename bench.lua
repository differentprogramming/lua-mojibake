local mojibake =  require 'mojibake'

 --use "bit" library if available (luajit and external), "bit32" if not (lua 5.2)
local bit_library_loaded,bit = pcall(require, "bit")
if not bit_library_loaded then
	bit = require "bit32"
end
local bnot, band, bor, bxor, lshift, rshift=bit.bnot, bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift


function readfile(filename)
	local f = io.open(filename, "rb");
	if f then
		local ret = f:read("*a");
		f:close()
		return ret;
	end
	return nil
end

function writefile(filename, buffer)
	local f = io.open(filename,"wb");
	if f then
		f:write(buffer);
		f:close();
		return true;
	end
	return false
end


local opt_name=1;
local opt_value=2;
local opt_desc=3;
local AllowedOptions=
{
	{"-nfkc",bor(mojibake.STABLE,mojibake.COMPOSE,mojibake.COMPAT),"compose+stable+compat"},
	{"-nfkd",bor(mojibake.STABLE,mojibake.DECOMPOSE,mojibake.COMPAT),"decompose+stable+compat"},
	{"-nfc",bor(mojibake.STABLE,mojibake.COMPOSE),"compose+stable"},
	{"-nfd",bor(mojibake.STABLE,mojibake.DECOMPOSE),"decompose+stable"},
	{"-casefold",mojibake.CASEFOLD,"Performs unicode case folding, to be able to do a\n"
		.."case-insensitive string comparison."},
	{"-stable",mojibake.STABLE,"Unicode Versioning Stability has to be respected."},
	{"-compat",mojibake.COMPAT,"formatting information is lost"},
	{"-compose",mojibake.COMPOSE,"Return a result with composed characters"},
	{"-decompose",mojibake.DECOMPOSE,"Return a result with decomposed characters"},
	{"-ignore",mojibake.IGNORE,"Strip \"default ignorable characters\""},
	{"-rejectna",mojibake.REJECTNA,"Return an error, if the input contains unassigned code points."},
	{"-nlf2ls",mojibake.NLF2LS,"Indicating that NLF-sequences (LF, CRLF, CR, NEL) are representing a line break, and should be converted to the unicode character for line separation (LS)."},
	{"-nlf2ps",mojibake.NLF2PS,"Indicating that NLF-sequences are representing a paragraph break, and should be converted to the unicode character for paragraph separation (PS)."},
	{"-nlf2lf",mojibake.NLF2LF,"Indicating that the meaning of NLF-sequences is unknown."},
	{"-stripcc",mojibake.STRIPCC,"Strips and/or convers control characters.\n"
		.."NLF-sequences are transformed into space, except if one of\n"
		.."the NLF2LS/PS/LF options is given.\n"
		.."HorizontalTab (HT) and FormFeed (FF) are treated as a\n"
		.."NLF-sequence in this case.\n"
		.."All other control characters are simply removed."},
	{"-charbound",mojibake.CHARBOUND," Inserts 0xFF bytes at the beginning of each sequence which\n"
		.."is representing a single grapheme cluster (see UAX#29)."},
	{"-lump",mojibake.LUMP,"Lumps certain characters together\n"
		.."(e.g. HYPHEN U+2010 and MINUS U+2212 to ASCII \"-\").\n"
		.."(See lump.txt for details.)\n"
		.."If NLF2LF is set, this includes a transformation of\n"
		.."paragraph and line separators to ASCII line-feed (LF)."},
	{"-stripmark",mojibake.STRIPMARK,"Strips all character markings\n"
	.."(non-spacing, spacing and enclosing) (i.e. accents)\n"
	.."NOTE: this option works only with COMPOSE or DECOMPOSE"},
};


local function main()
	 local j;
	 local options = 0;
	 local found_option=false;
	local EXIST_SUCCESS=0
	local EXIT_FAILURE=-1
	
	 for i = 1,#arg  do
		j=1
		while j<=#AllowedOptions do
			if arg[i] == AllowedOptions[j][opt_name] then
			   options = bor(options,AllowedOptions[j][opt_value]);
			    found_option=true;
			    break;
			end
			j=j+1
		 end
		 if (j==1+#AllowedOptions) then 
			 if (arg[i]:sub(1,1) == '-') then
				   io.stderr:write(string.format("unrecognized option: %s\n", arg[i]));
				   found_option=false;
			  end
			 if (not found_option) then
				   io.stderr:write(string.format("utf8proc bench use: -{conversion option}... input-file [output file]\nwhere the conversion options are:\n"));
				 for k=1,#AllowedOptions do
					 io.stderr:write(string.format("%s\t%s\n",AllowedOptions[k][opt_name],AllowedOptions[j][opt_desc]));
				 end
				return EXIT_FAILURE;
			 end
			
			 local will_write=false;
			  if i==#arg then io.stderr:write(string.format("no output file\n")); 
			 elseif i==#arg-1 then
				 will_write=true;
			 else
				   io.stderr:write(string.format("too many parameters\n"));
				   found_option=false;
			 end			 
			  
			  local src = readfile(arg[i]);
			  if not src then
				   io.stderr:write(string.format("error reading %s\n", arg[i]));
				   return EXIT_FAILURE;
			  end
			  local dest,ok,map;
			  map=mojibake.map
			  local start = os.clock();
			  for k = 0,9 do
				   ok,dest=pcall(map,src, options,mojibake.FORMAT_CODEPOINTS);
				if not ok then
					io.stderr:write(string.format("error while processing %d\n", dest.code));
					return EXIT_FAILURE;
				end
			  end
			  io.stdout:write(string.format("%s: %g\n", arg[i], (os.clock()-start)/10));
			  if (will_write) then
				  if (not writefile(arg[i+1],mojibake.reencode(dest))) then
					io.stderr:write(string.format("error writing %s\n", arg[i+1]));
					return EXIT_FAILURE;			  
				end
			  end
			  break
		end
	 end

	 return EXIT_SUCCESS;
end

return main()