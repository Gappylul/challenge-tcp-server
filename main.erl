-module(main).
-export([start/0, accepter/1, session/2]).

%% Helper functions
fail_session(Sock, Reason) ->
  io:format("ERROR: session failed ~w\n", [Reason]),
  gen_tcp:close(Sock),
  ok.

invalid_command(Sock) ->
  gen_tcp:send(Sock, "INVALID COMMAND\r\n"),
  gen_tcp:close(Sock),
  ok.

%% Start
start() ->
  {ok, LSock} = gen_tcp:listen(8888, [binary, {packet, 0}, {reuseaddr, true}, {active, false}]),
  spawn(?MODULE, accepter, [LSock]).

%% Different possible states
-spec session(State, Sock) -> ok when
  State :: command |
  {challenge, list(binary())} |
  {post, list(binary())} |
  {get, unicode:chardata()} |
  {accepted, list(binary()), binary()},
  Sock :: gen_tcp:socket().
%% Base state
session(command, Sock) ->
  case gen_tcp:recv(Sock, 0) of
    {ok, <<"POST\r\n">>} ->
      session({post, []}, Sock);
    {ok, <<"GET ", Id/binary>>} ->
      session({get, string:trim(Id)}, Sock);
    {ok, _} ->
      invalid_command(Sock);
    {error, Reason} ->
      fail_session(Sock, Reason)
  end;
%% Post state
session({post, Lines}, Sock) ->
  case gen_tcp:recv(Sock, 0) of
    {ok, <<"SUBMIT\r\n">>} ->
      session({challenge, Lines}, Sock);
    {ok, Line} ->
      session({post, [Line|Lines]}, Sock);
    {error, Reason} ->
      fail_session(Sock, Reason)
  end;
%% Challenge state
session({challenge, Lines}, Sock) ->
  Challenge = binary:encode_hex(crypto:strong_rand_bytes(32)),
  gen_tcp:send(Sock, [<<"CHALLENGE ">>, Challenge, <<"\r\n">>]),
  session({accepted, Lines, Challenge}, Sock);
%% Accepted state
session({accepted, Lines, Challenge}, Sock) ->
  case gen_tcp:recv(Sock, 0) of
    {ok, <<"ACCEPTED ", Suffix/binary>>} ->
      case binary:encode_hex(crypto:hash(sha256, [Lines, Challenge, <<"\r\n">>, Suffix])) of
        <<"000000", _/binary>> ->
          Id = binary:encode_hex(crypto:strong_rand_bytes(32)),
          gen_tcp:send(Sock, [Id, <<"\r\n">>]),
          gen_tcp:close(Sock),
          ok;
        _ ->
          gen_tcp:send(Sock, <<"CHALLENGE FAILED\r\n">>),
          gen_tcp:close(Sock),
          ok
      end;
    {ok, _} ->
      invalid_command(Sock);
    {error, Reason} ->
      fail_session(Sock, Reason)
  end,
  'TODO';
%% Get state
session({get, Id}, Sock) ->
  io:format("TODO: GET ~s\n", [Id]),
  gen_tcp:close(Sock),
  ok.

%% Loop the socket and spawn subsessions
accepter(LSock) ->
  {ok, Sock} = gen_tcp:accept(LSock),
  spawn(?MODULE, session, [command, Sock]),
  accepter(LSock).