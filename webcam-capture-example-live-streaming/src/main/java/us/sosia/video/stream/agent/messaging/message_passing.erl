%% @author David
%% @doc @todo Add description to message_passing.
%% @author David Pearson
%% @doc @todo Add description to token_ring.
%% This module inspired by trigonakis.com's Intro to Erlang: Message Passing segment

%%To Do -- Receiver code, additional uni/multi capabilities, how to integrate Han's code.

-module(message_passing).
-export([unicastSend/1, multicastSend/1, recvMsg/1, start/1, updateNodes/2, getSenderFullName/2]).


unicastSend({Name, Node, Payload}) ->
	io:format("Passed in name ~p, node ~p, and payload ~p~n", [Name, Node, Payload]),
	{Name,Node}!{Payload,node()},
	io:format("successfully sent message to ~p (~p)~n", [Name, Node]).
	%recvMsg() can't go here, b/c it doesn't return to RPC


multicastSend({Name, Node, Payload, Users}) ->
	case lists:keytake(Name, 1, Users) of
		{_, {NodeName, IP}, UserList} -> io:format("found user ~p with ip ~p~nOriginal tuple list is ~p", [NodeName, IP, Users]), 
										    unicastSend({NodeName, list_to_atom(lists:concat([NodeName, '@', IP])), Payload}),
											io:format("Data is ~p~n", [UserList]),
											case UserList =/= [] of
												true ->	[NextNodeInfo|_] = UserList,
														{NextNodeName,_} = NextNodeInfo,
														io:format("NNI: ~p~n", [NextNodeName]), 
														multicastSend({NextNodeName, Node, Payload, UserList});
												_ -> io:format("bleh") %need to get rid of the printout
											end;
		false -> io:format("failed to find user ~p~n", [Name]);
		Values -> io:format("Failed and found ~p~n", [Values])
 	end.


recvMsg(CurNodeList) ->
	%Will need to be modified based on what we need to do at Erlang's level. 
	%io:format("In recvMsg(), node list is ~p~n", [CurNodeList]),
	receive
		{Payload, FromName} ->        
		io:format("Got message ~p from ~p!~n", [Payload, FromName]),
		%io:format("Node list is ~p~n", [NodeList]),	%here we should check to see if we have a monitor connection to this node, and make one if not...if sender_server, check for the src@serverIP in the list (create as separate function)
		case Payload of %here we can add a bunch of cases for tokens, etc...
			{Sender, _, ack, _} -> io:format("Got an ack; done sending.~n", []),
				   SenderFN = getSenderFullName(FromName, Sender), %need this, but it fails now b/c Sender is a PID and not a name...must fix!
				   NodeList = updateNodes(CurNodeList, SenderFN),
				   io:format("NodeList after call is ~p~n", [NodeList]),
				   recvMsg(NodeList);
			{Sender, Me, _, _} ->
				 SenderFN = getSenderFullName(FromName, Sender),
				 unicastSend({Sender, SenderFN, {Me, Sender, ack, 1}}),
				 unicastSend({sender_server, FromName, {Me, sender_server, ack, 1}}), %need this line (right now) to make it respond and stop waiting 
				 NodeList = updateNodes(CurNodeList, SenderFN),
				 io:format("NodeList after call is ~p~n", [NodeList]),
				 %Logic will need to be added to make the payload dynamic instead of hard-coded
				 recvMsg(NodeList);
			nodedown -> %one of the nodes we're monitoring went down
				io:format("Node ~p has failed ~n", [FromName]); %we may want to interface upwards with our Java receiver here, or handle stuff at this level
			_ -> io:format("Message does not match an expected format~n", []) %shouldn't happen unless the message is malformed
		end
	end,
	otherthing.


updateNodes(CurNodeList, Candidate) ->
	%This function is used to keep track of which nodes are monitored.
	%Any node passed in that is not on the node list must be monitored 
	%and then added to the node list. Nodes already on the list should 
	%not be added again. Nodes that have died (which we'll know because
	%a 'DOWN' message will be sent to the user node) should be demonitored
	%and then removed. A timeout/heartbeat style of choosing when to remove
	%the node may be implemented if necessary.
	
	%io:format("Candidate ~p in Current list ~p?~n", [Candidate, CurNodeList]),
	case lists:member(Candidate, CurNodeList) of
	        false ->
	            io:format("Could not find ~p in list ~p~n", [Candidate, CurNodeList]),
				erlang:monitor_node(Candidate, true),
				lists:append(CurNodeList, [Candidate]);
	        true ->
				io:format("Found ~p in list ~p~n", [Candidate, CurNodeList]),
				NodeList = CurNodeList
	end.


getSenderFullName(FromName, Sender) ->
	[_|IP] = re:split(atom_to_list(FromName), "@", [{return, list}]), %extract the IP of the sender
    [IP_raw|_] = IP, %have to do this to make it a list, even though it looks like a list now...
	list_to_atom(lists:concat([Sender, '@', list_to_atom(IP_raw)])). %sender's full name, including IP	


start(Name) ->
	%IP = getMyIP(inet:getiflist()),
	NodeList = [], %don't need to include self in this
	case register(Name, spawn(message_passing, recvMsg, [NodeList])) of
		true -> %yes -> 
			io:format("Successful add~n");
		false -> %no -> 
			io:format("Unable to add ~p~n", [Name])
	end.