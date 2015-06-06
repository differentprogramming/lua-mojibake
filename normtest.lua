local mojibake = require 'mojibake'
local test = require 'unicode_test'
local encode = test.encode

local 	NFD,NFC,NFKD,NFKC = mojibake.NFD,mojibake.NFC,mojibake.NFKD,mojibake.NFKC;
local check = test.check

function CHECK_NORM(NRM, fn, norm, src) 
    local ok,src_norm = pcall(fn,src);
    if type(norm)=='table' then norm=table.concat(norm) end
    if type(src_norm)=='table' then src_norm=table.concat(src_norm) end
--    local _ =
    check(ok, function () if type(src)=='table' then src=table.concat(src) end return "error on %s for %s {%s} -> %s {%s}", NRM, src,table.concat(table.pack(string.byte(src,1,#src)),","), norm,table.concat(table.pack(string.byte(src,1,#norm)),",") end);
    check(norm==src_norm, function () if type(src)=='table' then src=table.concat(src) end return "failed %s for %s {%s} -> %s {%s} instead %s {%s}", NRM, src,table.concat(table.pack(string.byte(src,1,#src)),","), norm,table.concat(table.pack(string.byte(norm,1,#norm)),","),src_norm,table.concat(table.pack(string.byte(src_norm,1,#src_norm)),",") end); 
--    print("passed " .. NRM .. ' line:' .. test.lineno .. " '" .. src ..' {'..table.concat(table.pack(string.byte(src,1,#src)),",")  .."} '->'" .. norm .. "' {".. table.concat(table.pack(string.byte(norm,1,#norm)),",") .. "} got " .. src_norm .. "' {".. table.concat(table.pack(string.byte(src_norm,1,#src_norm)),",") .. "}")
end

function main()
     local buf = nil;
     local bufsize = 0;
     local f = io.open("C:/lua/workspace/mojibake/NormalizationTest.txt", "r");
--     local f = io.open("NormalizationTest.txt", "r");
     local source, NFC_buf, NFD_buf, NFKC_buf, NFKD_buf;

     check(f, function () return "error opening NormalizationTest.txt" end);
      buf=f:read('*l')
     while buf  do
          local offset;
          test.lineno = test.lineno+1;

          if (buf:sub(1,1) == '@') then
               print(string.format("line %d: %s", test.lineno, buf:sub(2)));
               goto continue_loop;
          elseif (test.lineno % 1000 == 0) then
              print(string.format("checking line %d...", test.lineno));
          end
	  
          if (buf:sub(1,1) == '#') then goto continue_loop; end
	  source = {}
          offset = encode(source, buf,1);
	  NFC_buf = {}
          offset = encode(NFC_buf, buf, offset);
	  NFD_buf = {}
          offset = encode(NFD_buf, buf, offset);
	  NFKC_buf = {}
          offset = encode(NFKC_buf, buf, offset);
	  NFKD_buf = {}
          offset = encode(NFKD_buf, buf, offset);

          CHECK_NORM('NFC',NFC, NFC_buf, source);
          CHECK_NORM('NFC',NFC, NFC_buf, NFC_buf);
          CHECK_NORM('NFC',NFC, NFC_buf, NFD_buf);
          CHECK_NORM('NFC',NFC, NFKC_buf, NFKC_buf);
          CHECK_NORM('NFC',NFC, NFKC_buf, NFKD_buf);

          CHECK_NORM('NFD',NFD, NFD_buf, source);
          CHECK_NORM('NFD',NFD, NFD_buf, NFC_buf);
          CHECK_NORM('NFD',NFD, NFD_buf, NFD_buf);
          CHECK_NORM('NFD',NFD, NFKD_buf, NFKC_buf);
          CHECK_NORM('NFD',NFD, NFKD_buf, NFKD_buf);

          CHECK_NORM('NFKC',NFKC, NFKC_buf, source);
          CHECK_NORM('NFKC',NFKC, NFKC_buf, NFC_buf);
          CHECK_NORM('NFKC',NFKC, NFKC_buf, NFD_buf);
          CHECK_NORM('NFKC',NFKC, NFKC_buf, NFKC_buf);
          CHECK_NORM('NFKC',NFKC, NFKC_buf, NFKD_buf);

          CHECK_NORM('NFKD',NFKD, NFKD_buf, source);
          CHECK_NORM('NFKD',NFKD, NFKD_buf, NFC_buf);
          CHECK_NORM('NFKD',NFKD, NFKD_buf, NFD_buf);
          CHECK_NORM('NFKD',NFKD, NFKD_buf, NFKC_buf);
          CHECK_NORM('NFKD',NFKD, NFKD_buf, NFKD_buf);
	  ::continue_loop::
      buf=f:read('*l')
     end
     f:close();
     print(string.format("Passed tests after %d lines!", test.lineno))
end

main()
