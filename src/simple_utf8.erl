%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc
%%%
%%% Very simple module to translate binaries into lists of utf8 codepoints and
%%% viceversa.
%%%
%%% @end
%%% @copyright Marcelo Gornstein <marcelog@gmail.com>
%%% @author Marcelo Gornstein <marcelog@gmail.com>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(simple_utf8).
-author('marcelog@gmail.com').
-github("https://github.com/marcelog").
-homepage("http://marcelog.github.io/").
-license("Apache License 2.0").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type codepoint():: non_neg_integer().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Exports
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-export([bin_to_cp/1, cp_to_bin/1]).
-export_type([codepoint/0]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Public API.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc Translates a binary stream into a list of utf8 codepoints.
-spec bin_to_cp(binary()) -> [codepoint()].
bin_to_cp(Bin) when is_binary(Bin) ->
	bin_to_cp(Bin, []).

bin_to_cp(<<>>, Acc) ->
  lists:reverse(Acc);

%% 1-Byte codepoints.
bin_to_cp(<<0:1, CodePoint:7/integer, Rest/binary>>, Acc) ->
  bin_to_cp(Rest, [CodePoint|Acc]);

%% 2-Byte codepoints.
bin_to_cp(<<6:3, B1:5, 2:2, B2:6, Rest/binary>>, Acc
) ->
  <<CodePoint:16/integer>> = <<0:5/integer, B1:5/integer, B2:6/integer>>,
  bin_to_cp(Rest, [CodePoint|Acc]);

%% 3-Byte codepoints.
bin_to_cp(<<14:4, B1:4, 2:2, B2:6, 2:2, B3:6, Rest/binary>>, Acc) ->
  <<CodePoint:16/integer>> = <<B1:4/integer, B2:6/integer, B3:6/integer>>,
  bin_to_cp(Rest, [CodePoint|Acc]);

%% 4-Byte codepoints.
bin_to_cp(<<30:5, B1:3, 2:2, B2:6, 2:2, B3:6, 2:2, B4:6, Rest/binary>>, Acc) ->
  <<CodePoint:32/integer>> = <<
    0:11/integer, B1:3/integer, B2:6/integer, B3:6/integer, B4:6/integer
  >>,
  bin_to_cp(Rest, [CodePoint|Acc]);

%% 5-Byte codepoints.
bin_to_cp(
  <<62:6, B1:2, 2:2, B2:6, 2:2, B3:6, 2:2, B4:6, 2:2, B5:6, Rest/binary>>, Acc
) ->
  <<CodePoint:32/integer>> = <<
    0:6/integer,
    B1:2/integer, B2:6/integer, B3:6/integer, B4:6/integer, B5:6/integer
  >>,
  bin_to_cp(Rest, [CodePoint|Acc]);

%% 6-Byte codepoints.
bin_to_cp(<<
  126:7, B1:1, 2:2, B2:6, 2:2, B3:6, 2:2, B4:6, 2:2, B5:6, 2:2, B6:6,
  Rest/binary
>>, Acc) ->
  <<CodePoint:32/integer>> = <<
    0:1/integer,
    B1:1/integer, B2:6/integer, B3:6/integer,
    B4:6/integer, B5:6/integer, B6:6/integer
  >>,
  bin_to_cp(Rest, [CodePoint|Acc]);

bin_to_cp(Bin, Acc) ->
  throw({invalid_utf8_string, {
    {decoded_so_far, lists:reverse(Acc)},
    {left, Bin}
  }}).

%% @doc Transforms a list of utf8 codepoints into a binary stream.
-spec cp_to_bin([codepoint()]) -> binary().
cp_to_bin(CodePoints) ->
  cp_to_bin(CodePoints, <<>>).

cp_to_bin([], Acc) ->
  Acc;

%% 1-byte pointcodes.
cp_to_bin([H|Rest], Acc) when H >= 16#0 andalso H =< 16#7f ->
  cp_to_bin(Rest, <<Acc/binary, 0:1/integer, H:7/integer>>);

%% 2-bytes pointecodes.
cp_to_bin([H|Rest], Acc) when H >= 16#80 andalso H =< 16#7ff ->
  B2 = (H band 2#0000000000111111),
  B1 = (H band 2#0000011111000000) bsr 6,
  cp_to_bin(Rest, <<
    Acc/binary,
    6:3/integer, B1:5/integer,
    2:2, B2:6/integer
  >>);

%% 3-byte pointecodes.
cp_to_bin([H|Rest], Acc) when H >= 16#800 andalso H =< 16#ffff ->
  B3 = (H band 2#0000000000111111),
  B2 = (H band 2#0000111111000000) bsr 6,
  B1 = (H band 2#1111000000000000) bsr 12,
  cp_to_bin(Rest, <<
    Acc/binary,
    14:4/integer, B1:4/integer,
    2:2, B2:6/integer,
    2:2, B3:6/integer
  >>);

%% 4-byte pointecodes.
cp_to_bin([H|Rest], Acc) when H >= 16#10000 andalso H =< 16#1fffff ->
  B4 = (H band 2#00000000000000000000000000111111),
  B3 = (H band 2#00000000000000000000111111000000) bsr 6,
  B2 = (H band 2#00000000000000111111000000000000) bsr 12,
  B1 = (H band 2#00000000000111000000000000000000) bsr 18,
  cp_to_bin(Rest, <<
    Acc/binary,
    30:5/integer, B1:3/integer,
    2:2, B2:6/integer,
    2:2, B3:6/integer,
    2:2, B4:6/integer
  >>);

%% 5-byte pointecodes.
cp_to_bin([H|Rest], Acc) when H >= 16#200000 andalso H =< 16#3ffffff ->
  B5 = (H band 2#00000000000000000000000000111111),
  B4 = (H band 2#00000000000000000000111111000000) bsr 6,
  B3 = (H band 2#00000000000000111111000000000000) bsr 12,
  B2 = (H band 2#00000000111111000000000000000000) bsr 18,
  B1 = (H band 2#00000011000000000000000000000000) bsr 24,
  cp_to_bin(Rest, <<
    Acc/binary,
    62:6/integer, B1:2/integer,
    2:2, B2:6/integer,
    2:2, B3:6/integer,
    2:2, B4:6/integer,
    2:2, B5:6/integer
  >>);

%% 6-byte pointecodes.
cp_to_bin([H|Rest], Acc) when H >= 16#4000000 andalso H =< 16#7fffffff ->
  B6 = (H band 2#00000000000000000000000000111111),
  B5 = (H band 2#00000000000000000000111111000000) bsr 6,
  B4 = (H band 2#00000000000000111111000000000000) bsr 12,
  B3 = (H band 2#00000000111111000000000000000000) bsr 18,
  B2 = (H band 2#00111111000000000000000000000000) bsr 24,
  B1 = (H band 2#01000000000000000000000000000000) bsr 32,
  cp_to_bin(Rest, <<
    Acc/binary,
    126:7/integer, B1:1/integer,
    2:2, B2:6/integer,
    2:2, B3:6/integer,
    2:2, B4:6/integer,
    2:2, B5:6/integer,
    2:2, B6:6/integer
  >>);

cp_to_bin([H|Rest], Acc) ->
  throw({invalid_utf8_codepoint, {
    {codepoint, H},
    {decoded_so_far, Acc},
    {left, Rest}
  }}).
