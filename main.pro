% suleyman tolga acar
% 2021400237
% compiling: yes
% complete: yes


:- ['cmpefarm.pro'].
:- init_from_map.

get_nth_element([H|_], 0, H).
get_nth_element([_|T], N, E) :-
    N > 0,
    N1 is N - 1,
    get_nth_element(T, N1, E).

get_min_element([H], H).
get_min_element([H|T], Min) :- get_min_element(T, Min1), Min is min(H, Min1).

get_index([H|_], H, 0).
get_index([_|T], E, Index) :- get_index(T, E, Index1), Index is Index1 + 1.

get_length([], 0).
get_length([_|T], Length) :- get_length(T, Length1), Length is Length1 + 1.

append_list([], L, L).
append_list([H|T], L, [H|Result]) :- append_list(T, L, Result).

% 1- agents_distance(+Agent1, +Agent2, -Distance)
agents_distance(Agent1, Agent2, Distance) :-
    Distance is abs(Agent1.x - Agent2.x) + abs(Agent1.y - Agent2.y).

% 2- number_of_agents(+State, -NumberOfAgents)
number_of_agents([Agents, _, _, _], NumberOfAgents) :-
    dict_pairs(Agents, _, AgentsList),
    get_length(AgentsList, NumberOfAgents).

% 3- value_of_farm(+State, -Value)
value_of_farm([Agents, Objects, _, _], Value) :-
    dict_pairs(Agents, _, AgentsDictList), dict_pairs(Objects, _, ObjectsDictList),
    findall(Agent, (member(_-Agent, AgentsDictList), Agent.subtype \= wolf), AgentsList),
    findall(Object, (member(_-Object, ObjectsDictList)), ObjectsList),
    sum_values(AgentsList, 0, AgentsValue), sum_values(ObjectsList, 0, ObjectsValue),
    Value is AgentsValue + ObjectsValue.
    
sum_values([], Acc, Acc).
sum_values([Object | Rest], Acc, Total) :-
    Subtype = Object.subtype,
    value(Subtype, Value),
    NewAcc is Acc + Value,
    sum_values(Rest, NewAcc, Total).

% 4- find_food_coordinates(+State, +AgentId, -Coordinates)
find_food_coordinates([Agents, Objects, _, _], AgentId, Coordinates) :-
    Agent = Agents.AgentId,
    dict_pairs(Objects, _, ObjectsList),
    dict_pairs(Agents, _, AgentsList),
    findall((X, Y), (member(_-Object, ObjectsList), can_eat(Agent.subtype, Object.subtype), Object.x = X, Object.y = Y), ObjectCoordinates),
    findall((X, Y), (member(_-OtherAgent, AgentsList), can_eat(Agent.subtype, OtherAgent.subtype), OtherAgent.x = X, OtherAgent.y = Y), AgentCoordinates),
    append_list(ObjectCoordinates, AgentCoordinates, Coordinates).

% 5- find_nearest_agent(+State, +AgentId, -Coordinates, -NearestAgent)
find_nearest_agent([Agents, _, _, _], AgentId, Coordinates, NearestAgent) :-
    Agent = Agents.AgentId,
    dict_pairs(Agents, _, AgentsList),
    findall(OtherAgent, (member(_-OtherAgent, AgentsList), OtherAgent \= Agent), OtherAgents),
    findall(Distance, (member(OtherAgent, OtherAgents), agents_distance(Agent, OtherAgent, Distance)), Distances),
    get_min_element(Distances, MinDistance),
    get_index(Distances, MinDistance, MinIndex),
    get_nth_element(OtherAgents, MinIndex, NearestAgent),
    Coordinates = (NearestAgent.x, NearestAgent.y).

% 6- find_nearest_food(+State, +AgentId, -Coordinates, -FoodType, -Distance)
find_nearest_food([Agents, Objects, _, _], AgentId, Coordinates, FoodType, Distance) :-
    Agent = Agents.AgentId,
    dict_pairs(Agents, _, AgentsList),
    dict_pairs(Objects, _, ObjectsList),
    findall(Object, (member(_-Object, ObjectsList), can_eat(Agent.subtype, Object.subtype)), ObjectFoods),
    findall(OtherAgent, (member(_-OtherAgent, AgentsList), can_eat(Agent.subtype, OtherAgent.subtype)), AgentFoods),
    append_list(ObjectFoods, AgentFoods, Foods),
    findall(Distance, (member(Food, Foods), agents_distance(Agent, Food, Distance)), Distances),
    get_min_element(Distances, MinDistance),
    get_index(Distances, MinDistance, MinIndex),
    get_nth_element(Foods, MinIndex, NearestFood),
    Coordinates = (NearestFood.x, NearestFood.y),
    FoodType = NearestFood.subtype,
    Distance = MinDistance.

% 7- move_to_coordinate(+State, +AgentId, +X, +Y, -ActionList, +DepthLimit)
move_to_coordinate(State, AgentId, X, Y, ActionList, DepthLimit) :-
    DepthLimit > 0,
    DepthLimit1 is DepthLimit - 1,
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    can_move(Agent.subtype, Direction),
    move(State, AgentId, Direction, NewState),
    ActionList = [Direction | Rest],
    move_to_coordinate(NewState, AgentId, X, Y, Rest, DepthLimit1).

move_to_coordinate(State, AgentId, X, Y, ActionList, _) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    Agent.x = X,
    Agent.y = Y,
    ActionList = [].
    

% 8- move_to_nearest_food(+State, +AgentId, -ActionList, +DepthLimit)
move_to_nearest_food(State, AgentId, ActionList, DepthLimit) :-
    find_nearest_food(State, AgentId, (X, Y), _, _),
    move_to_coordinate(State, AgentId, X, Y, ActionList, DepthLimit).

% 9- consume_all(+State, +AgentId, -NumberOfMoves, -Value, NumberOfChildren +DepthLimit)
consume_all(State, AgentId, NumberOfMoves, Value, NumberOfChildren, DepthLimit) :-
    consume_all(State, AgentId, 0, NumberOfMoves, Value, NumberOfChildren, DepthLimit).

consume_all(State, AgentId, NumberOfMovesAcc, NumberOfMovesAcc, Value, NumberOfChildren, _) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    \+ find_nearest_food(State, AgentId, _, _, _),
    value_of_farm(State, Value),
    NumberOfChildren = Agent.children.
    
consume_all(State, AgentId, NumberOfMovesAcc, NumberOfMoves, Value, NumberOfChildren, DepthLimit) :-
    DepthLimit > 0,
    find_nearest_food(State, AgentId, (X, Y), _, _),
    bfs(State, AgentId, (X, Y), ShortestPathDistance, NewState),
    DepthLimit1 is DepthLimit - ShortestPathDistance,
    NumberOfMovesAcc1 is NumberOfMovesAcc + ShortestPathDistance,
    consume_all(NewState, AgentId, NumberOfMovesAcc1, NumberOfMoves, Value, NumberOfChildren, DepthLimit1).


bfs(State, AgentId, Goal, Distance, NewState) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    bfs_queue(AgentId, [(State, 0)], Goal, [(Agent.x, Agent.y)], Distance, NewState).

bfs_queue(AgentId, [(State, Distance)|_], Goal, _, Distance, NewState) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    Goal = (Agent.x, Agent.y),
    eat(State, AgentId, NewState).

bfs_queue(AgentId, [(State, Dist) | RestQueue], Goal, Visited, Distance, NewState) :-
    findall((NewState, Dist1), 
        (
            State = [Agents, _, _, _],
            Agent = Agents.AgentId,
            can_move(Agent.subtype, Direction),
            move(State, AgentId, Direction, NewState),
            \+ member(NewState, Visited),
            Dist1 is Dist + 1
        ),
    Neighbors),
    append(RestQueue, Neighbors, NewQueue),
    findall(N, member((N, _), Neighbors), NewVisitedNodes),
    union(NewVisitedNodes, Visited, NewVisited),
    bfs_queue(AgentId, NewQueue, Goal, NewVisited, Distance, NewState).


