% suleyman tolga acar
% 2021400237
% compiling: yes
% complete: yes


:- ['cmpefarm.pro'].
:- init_from_map.

% Some helper functions
quicksort([], []). 
quicksort([H|T], Sorted) :- 
    partition(T, H, Less, Greater),  
    quicksort(Less, SortedLess),    
    quicksort(Greater, SortedGreater),  
    append_list(SortedLess, [H|SortedGreater], Sorted). 

partition([], _, [], []).
partition([H|T], Pivot, [H|Less], Greater) :- 
    H < Pivot,
    partition(T, Pivot, Less, Greater).
partition([H|T], Pivot, Less, [H|Greater]) :- 
    H >= Pivot,
    partition(T, Pivot, Less, Greater).

get_nth_element([H|_], 0, H).
get_nth_element([_|T], N, E) :-
    N > 0,
    N1 is N - 1,
    get_nth_element(T, N1, E).

get_min_element(List, Min) :-
    member(Min, List),
    \+ (member(X, List), X < Min).

get_index([H|_], H, 0).
get_index([_|T], E, Index) :- get_index(T, E, Index1), Index is Index1 + 1.

get_length([], 0).
get_length([_|T], Length) :- get_length(T, Length1), Length is Length1 + 1.

append_list([], L, L).
append_list([H|T], L, [H|Result]) :- append_list(T, L, Result).

% 1- agents_distance(+Agent1, +Agent2, -Distance)
agents_distance(Agent1, Agent2, Distance) :-
    % Calculate the Manhattan distance between two agents
    Distance is abs(Agent1.x - Agent2.x) + abs(Agent1.y - Agent2.y).

% 2- number_of_agents(+State, -NumberOfAgents)
number_of_agents([Agents, _, _, _], NumberOfAgents) :-
    % Get the list of agents and calculate its length
    dict_pairs(Agents, _, AgentsList),
    get_length(AgentsList, NumberOfAgents).

% 3- value_of_farm(+State, -Value)
value_of_farm([Agents, Objects, _, _], Value) :-
    % Get the list of agents and objects, then sum their values
    dict_pairs(Agents, _, AgentsDictList), 
    dict_pairs(Objects, _, ObjectsDictList),
    % Filter wolves out because they don't have value
    findall(Agent, (member(_-Agent, AgentsDictList), Agent.subtype \= wolf), AgentsList),
    findall(Object, (member(_-Object, ObjectsDictList)), ObjectsList),
    sum_values(AgentsList, 0, AgentsValue), 
    sum_values(ObjectsList, 0, ObjectsValue),
    Value is AgentsValue + ObjectsValue.

% Helper function for summing values of agents and objects
sum_values([], Acc, Acc).
sum_values([Object | Rest], Acc, Total) :-
    Subtype = Object.subtype,
    value(Subtype, Value),
    NewAcc is Acc + Value,
    sum_values(Rest, NewAcc, Total).

% 4- find_food_coordinates(+State, +AgentId, -Coordinates)
find_food_coordinates([Agents, Objects, _, _], AgentId, Coordinates) :-
    % Find all coordinates of foods that the agent can eat
    Agent = Agents.AgentId,
    dict_pairs(Objects, _, ObjectsList),
    dict_pairs(Agents, _, AgentsList),
    findall((X, Y), (member(_-Object, ObjectsList), can_eat(Agent.subtype, Object.subtype), Object.x = X, Object.y = Y), ObjectCoordinates),
    findall((X, Y), (member(_-OtherAgent, AgentsList), can_eat(Agent.subtype, OtherAgent.subtype), OtherAgent.x = X, OtherAgent.y = Y), AgentCoordinates),
    append_list(ObjectCoordinates, AgentCoordinates, Coordinates).

% 5- find_nearest_agent(+State, +AgentId, -Coordinates, -NearestAgent)
find_nearest_agent([Agents, _, _, _], AgentId, Coordinates, NearestAgent) :-
    % Find the nearest agent to the given agent
    Agent = Agents.AgentId,
    dict_pairs(Agents, _, AgentsList),
    % Filter out the agent itself
    findall(OtherAgent, (member(_-OtherAgent, AgentsList), OtherAgent \= Agent), OtherAgents),
    % Calculate distances between the agent and other agents
    findall(Distance, (member(OtherAgent, OtherAgents), agents_distance(Agent, OtherAgent, Distance)), Distances),
    % Find the nearest agent
    get_min_element(Distances, MinDistance),
    get_index(Distances, MinDistance, MinIndex),
    get_nth_element(OtherAgents, MinIndex, NearestAgent),
    Coordinates = (NearestAgent.x, NearestAgent.y).

% 6- find_nearest_food(+State, +AgentId, -Coordinates, -FoodType, -Distance)
find_nearest_food([Agents, Objects, _, _], AgentId, Coordinates, FoodType, Distance) :-
    % Find the nearest food to the given agent
    Agent = Agents.AgentId,
    dict_pairs(Agents, _, AgentsList),
    dict_pairs(Objects, _, ObjectsList),
    % Find all foods that the agent can eat from objects and other agents, then append them
    findall(Object, (member(_-Object, ObjectsList), can_eat(Agent.subtype, Object.subtype)), ObjectFoods),
    findall(OtherAgent, (member(_-OtherAgent, AgentsList), can_eat(Agent.subtype, OtherAgent.subtype)), AgentFoods),
    append_list(ObjectFoods, AgentFoods, Foods),
    % Calculate distances between the agent and foods, then sort them
    findall(Distance, (member(Food, Foods), agents_distance(Agent, Food, Distance)), Distances),
    quicksort(Distances, SortedDistances),
    !, % Cut to prevent backtracking after sorting
    % Used member/2 to get the minimum distance, also it gives the next nearest food when backtracking
    member(MinDistance, SortedDistances),
    get_index(Distances, MinDistance, MinIndex),
    get_nth_element(Foods, MinIndex, NearestFood),
    Coordinates = (NearestFood.x, NearestFood.y),
    FoodType = NearestFood.subtype,
    Distance = MinDistance.

% 7- move_to_coordinate(+State, +AgentId, +X, +Y, -ActionList, +DepthLimit)
move_to_coordinate(State, AgentId, X, Y, ActionList, _) :-
% Base case for move_to_coordinate
% If the agent is already at the target coordinates then return an empty action list
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    Agent.x = X,
    Agent.y = Y,
    ActionList = [].

% Recursive case for move_to_coordinate
move_to_coordinate(State, AgentId, X, Y, ActionList, DepthLimit) :-
    DepthLimit > 0,
    DepthLimit1 is DepthLimit - 1,
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    % Loop through all possible directions that the agent can move
    can_move(Agent.subtype, Direction),
    move(State, AgentId, Direction, NewState),
    % Populate the action list
    ActionList = [Direction | Rest],
    move_to_coordinate(NewState, AgentId, X, Y, Rest, DepthLimit1).

    
% 8- move_to_nearest_food(+State, +AgentId, -ActionList, +DepthLimit)
move_to_nearest_food(State, AgentId, ActionList, DepthLimit) :-
    % Find the nearest food and move to its coordinates
    find_nearest_food(State, AgentId, (X, Y), _, _),
    move_to_coordinate(State, AgentId, X, Y, ActionList, DepthLimit).

% 9- consume_all(+State, +AgentId, -NumberOfMoves, -Value, NumberOfChildren +DepthLimit)
consume_all(State, AgentId, NumberOfMoves, Value, NumberOfChildren, DepthLimit) :-
    find_nearest_food(State, AgentId, _, _, _),
    % Call consume_all/7 with an accumulator for the number of moves
    consume_all(State, AgentId, 0, NumberOfMoves, Value, NumberOfChildren, DepthLimit).
    
consume_all(State, AgentId, NumberOfMovesAcc, NumberOfMoves, Value, NumberOfChildren, DepthLimit) :-
    % Find the nearest food and calculate the shortest path to it
    find_nearest_food(State, AgentId, (X, Y), _, _),
    bfs(State, AgentId, (X, Y), ShortestPathDistance, NewState, DepthLimit),
    !, % Cut to prevent backtracking after finding the shortest path
    NumberOfMovesAcc1 is NumberOfMovesAcc + ShortestPathDistance,
    % Call consume_all/7 recursively with the new state to consume remaining foods
    consume_all(NewState, AgentId, NumberOfMovesAcc1, NumberOfMoves, Value, NumberOfChildren, DepthLimit).

% Base case for consume_all, it populates the number of moves and value of the farm
consume_all(State, AgentId, NumberOfMovesAcc, NumberOfMovesAcc, Value, NumberOfChildren, _) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    value_of_farm(State, Value),
    NumberOfChildren = Agent.children.

bfs(State, AgentId, Goal, Distance, NewState, DepthLimit) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    bfs_queue(AgentId, [(State, 0)], Goal, [(Agent.x, Agent.y)], Distance, NewState, DepthLimit).

% Base case for bfs_queue
% If the agent is at the goal coordinates then eat the food and return the new state
bfs_queue(AgentId, [(State, Distance)|_], Goal, _, Distance, NewState, _) :-
    State = [Agents, _, _, _],
    Agent = Agents.AgentId,
    Goal = (Agent.x, Agent.y),
    eat(State, AgentId, NewState).

% Recursive case for bfs_queue
bfs_queue(AgentId, [(State, Dist) | RestQueue], Goal, Visited, Distance, NewState, DepthLimit) :-
    % Find all neighbors of the current state and append them to the queue
    findall((NewState, Dist1), 
        (
            State = [Agents, _, _, _],
            Agent = Agents.AgentId,
            can_move(Agent.subtype, Direction),
            move(State, AgentId, Direction, NewState),
            \+ member(NewState, Visited),
            Dist1 is Dist + 1,
            Dist1 =< DepthLimit
        ),
    Neighbors),
    append_list(RestQueue, Neighbors, NewQueue),
    % Mark the neighbors as visited and append them to the visited list
    findall(N, member((N, _), Neighbors), NewVisitedNodes),
    append_list(NewVisitedNodes, Visited, NewVisited),
    % Recursive call with the new queue, visited list, and state
    bfs_queue(AgentId, NewQueue, Goal, NewVisited, Distance, NewState, DepthLimit).
