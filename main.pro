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

append_list([], L, L).
append_list([H|T], L, [H|Result]) :- append_list(T, L, Result).

% 1- agents_distance(+Agent1, +Agent2, -Distance)
agents_distance(Agent1, Agent2, Distance) :-
    Distance is abs(Agent1.x - Agent2.x) + abs(Agent1.y - Agent2.y).

% 2- number_of_agents(+State, -NumberOfAgents)
number_of_agents([Agents, _, _, _], NumberOfAgents) :-
    dict_pairs(Agents, _, AgentsList),
    length(AgentsList, NumberOfAgents).

% 3- value_of_farm(+State, -Value)
value_of_farm([Agents, Objects, _, _], Value) :-
    dict_pairs(Agents, _, AgentsList), dict_pairs(Objects, _, ObjectsList),
    sum_values(AgentsList, 0, AgentsValue), sum_values(ObjectsList, 0, ObjectsValue),
    Value is AgentsValue + ObjectsValue.
    
sum_values([], Acc, Acc).
sum_values([Pair | Rest], Acc, Total) :-
    Pair = _-Object,
    Subtype = Object.subtype,
    value(Subtype, Value),
    NewAcc is Acc + Value,
    sum_values(Rest, NewAcc, Total).

% 4- find_food_coordinates(+State, +AgentId, -Coordinates)
find_food_coordinates([Agents, Objects, _, _], AgentId, Coordinates) :-
    Agent = Agents.AgentId,
    dict_pairs(Objects, _, ObjectsList),
    findall((X, Y), (member(_-Object, ObjectsList), can_eat(Agent.subtype, Object.subtype), Object.x = X, Object.y = Y), Coordinates).

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

% 8- move_to_nearest_food(+State, +AgentId, -ActionList, +DepthLimit)

% 9- consume_all(+State, +AgentId, -NumberOfMoves, -Value, NumberOfChildren +DepthLimit)


