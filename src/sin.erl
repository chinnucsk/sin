-module(sin).
-author("Richard Giliam : http://github.com/nirosys").

-export([main/0]).
-compile(export_all).

-on_load(init/0).

-define(GENERAL_URL, "http://us.battle.net/d3/en/forum/3354739/").
-define(PROFILE_BASE_URL, "http://us.battle.net/api/d3/profile/").
-define(PROFILE_DIR, "./profiles/").

init() ->
    case application:start(inets) of
        ok -> ok;
        {error, {already_started, inets}} -> ok;
        Error -> Error
    end.

main() ->
    parseIndexPage(fetchUrl(?GENERAL_URL)).

fetchUrl(Url) ->
    io:format("Fetching: ~s~n", [Url]),
    case httpc:request(Url) of
        {ok, {_, _, Response}} -> Response;
        {error, Reason} -> {error, Reason}
    end.

parseIndexPage(PageResponse) ->
    Parsed = mochiweb_html:parse(PageResponse),
    % Find Next button
    % Find Posts..
    [NextUrl, _] = mochiweb_xpath:execute("//li[@class='cap-item']/a/@href", Parsed),
    fetchTopics(mochiweb_xpath:execute("//td[@class = 'post-title']/a/@href", Parsed)).

fetchTopics([]) -> [];
fetchTopics([Topic | Rest]) ->
    %fetchTopic(Topic) + fetchTopics(Rest).
    NewUrl = string:concat(?GENERAL_URL, binary_to_list(Topic)),
    parseTopic(fetchUrl(NewUrl)) + fetchTopics(Rest).

parseTopic(TopicResponse) ->
    Parsed = mochiweb_html:parse(TopicResponse),
    Profiles = mochiweb_xpath:execute("//a[@class='view-d3-profile']/@href", Parsed),
    fetchProfiles(Profiles).


fetchProfiles([]) -> 0;
fetchProfiles([ProfileUrl | Rest]) ->
    ProfileUrlList = binary_to_list(ProfileUrl),
    ProfileNoSlash = string:strip(ProfileUrlList, right, $/),
    Profile = string:substr(ProfileNoSlash, string:rchr(ProfileNoSlash, $/)+1),
    io:format("~s~n", [Profile]),

    ProfileApiUrl = string:join([?PROFILE_BASE_URL, Profile, "/"], ""),

    ProfileJson = fetchUrl(ProfileApiUrl),
    io:format("~s~n", [ProfileJson]),

    OutputPath = string:join([?PROFILE_DIR, Profile, ".json"], ""),
    ok = file:write_file(OutputPath, [ProfileJson]),
    
    timer:sleep(500),

    1 + fetchProfiles(Rest).
