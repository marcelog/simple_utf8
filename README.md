# Simple UTF8 <-> binaries routines

## Binaries to UTF8 pointcodes

    simple_utf8:bin_to_cp(Bin).

## UTF8 pointcodes to binaries

    simple_utf8:cp_to_bin(CodePoints).

## Example
    1> Utf8Bin = simple_utf8:cp_to_bin("中國哲學書電子化計劃").
    <<228,184,173,229,156,139,229,147,178,229,173,184,230,155,
      184,233,155,187,229,173,144,229,140,150,232,168,136,229,
      138,...>>
    2> "中國哲學書電子化計劃" = simple_utf8:bin_to_cp(Utf8Bin).
    [20013,22283,21746,23416,26360,38651,23376,21270,35336,
     21123]

