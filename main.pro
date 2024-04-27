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


% 1- agents_distance(+Agent1, +Agent2, -Distance)
agents_distance(Agent1, Agent2, Distance) :-
    Distance is abs(Agent1.x - Agent2.x) + abs(Agent1.y - Agent2.y).

% 2- number_of_agents(+State, -NumberOfAgents)
number_of_agents([Agents | _], NumberOfAgents) :-
    dict_pairs(Agents, _, AgentsList),
    length(AgentsList, NumberOfAgents).

% 3- value_of_farm(+State, -Value)
value_of_farm(State, Value) :-
    get_nth_element(State, 0, Agents), get_nth_element(State, 1, Objects),
    dict_pairs(Agents, _, AgentsList), dict_pairs(Objects, _, ObjectsList),
    sum_values(AgentsList, 0, AgentsValue), sum_values(ObjectsList, 0, ObjectsValue),
    Value is AgentsValue + ObjectsValue.
    
sum_values([], Acc, Acc).
sum_values([Pair | Rest], Acc, Total) :-
    _-Object = Pair,
    Subtype = Object.subtype,
    value(Subtype, Value),
    NewAcc is Acc + Value,
    sum_values(Rest, NewAcc, Total).

% 4- find_food_coordinates(+State, +AgentId, -Coordinates)

% 5- find_nearest_agent(+State, +AgentId, -Coordinates, -NearestAgent)

% 6- find_nearest_food(+State, +AgentId, -Coordinates, -FoodType, -Distance)

% 7- move_to_coordinate(+State, +AgentId, +X, +Y, -ActionList, +DepthLimit)

% 8- move_to_nearest_food(+State, +AgentId, -ActionList, +DepthLimit)

% 9- consume_all(+State, +AgentId, -NumberOfMoves, -Value, NumberOfChildren +DepthLimit)


