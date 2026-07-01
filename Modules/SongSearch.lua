-- Song search for ScreenSelectMusic.
--
-- Flow: SPACE on the wheel opens the engine's ScreenTextEntry keyboard; the typed
-- query is matched against every loaded song (title / artist / group); the matches
-- are written to the theme's preferred-sort file (Other/SongManager SearchResults.txt);
-- then the music wheel is pointed at SortOrder_Preferred and forced to rebuild so it
-- shows only the hits under a "Search Results" section. Picking any other sort (via
-- the sort menu) clears the search.
--
-- APIs confirmed against this OutFox build's LuaDocumentation (GetAllSongs,
-- SetPreferredSongs(string), ScreenTextEntry:Load, RageFileUtil, MusicWheel
-- ChangeSort/SetOpenSection).

local M = {}

local RESULTS_NAME = "SearchResults.txt"
local RESULTS_PATH = THEME:GetCurrentThemeDirectory() .. "Other/SongManager " .. RESULTS_NAME
local SECTION = "Search Results"

-- Songs whose title / artist / group contain ALL of the space-separated terms
-- (case-insensitive substring). "kos love" matches a song only if both appear.
function M.FindMatches(query)
	local terms = {}
	for t in query:lower():gmatch("%S+") do terms[#terms + 1] = t end
	if #terms == 0 then return {} end

	local matches = {}
	for _, song in ipairs(SONGMAN:GetAllSongs()) do
		local hay = ((song:GetDisplayFullTitle() or "") .. " "
			.. (song:GetTranslitMainTitle() or "") .. " "
			.. (song:GetDisplayArtist() or "") .. " "
			.. (song:GetTranslitArtist() or "") .. " "
			.. (song:GetGroupName() or "")):lower()
		local ok = true
		for _, term in ipairs(terms) do
			if not hay:find(term, 1, true) then ok = false break end
		end
		if ok then matches[#matches + 1] = song end
	end
	return matches
end

-- Preferred-sort file line for a song: "<Group>/<songFolder>".
local function songLine(song)
	local folder
	for p in song:GetSongDir():gmatch("[^/]+") do folder = p end
	return song:GetGroupName() .. "/" .. (folder or "")
end

-- Write the preferred-sort file. Returns true on success.
function M.WriteResults(songs)
	local f = RageFileUtil.CreateRageFile()
	if not f:Open(RESULTS_PATH, 2) then -- 2 = write (truncate)
		f:destroy()
		return false
	end
	f:PutLine("---" .. SECTION)
	for _, song in ipairs(songs) do
		f:PutLine(songLine(song))
	end
	f:Close()
	f:destroy()
	return true
end

-- Filter and apply. `wheel` is ScreenSelectMusic's MusicWheel. Returns match count
-- (or -1 for an empty/blank query, treated as a cancel).
function M.Apply(wheel, query)
	if not query or query:gsub("%s", "") == "" then return -1 end
	local matches = M.FindMatches(query)
	if #matches == 0 then
		SCREENMAN:SystemMessage("No songs match \"" .. query .. "\"")
		return 0
	end
	if not M.WriteResults(matches) then
		SCREENMAN:SystemMessage("Search: couldn't write results file")
		return 0
	end
	SONGMAN:SetPreferredSongs(RESULTS_NAME)
	-- Set the sort so the reloaded screen comes up on the results...
	if wheel then wheel:ChangeSort("SortOrder_Preferred") end
	-- ...then flag a reload. The live wheel caches its preferred list and won't show
	-- new results without a fresh screen; the poller in InputHandler.lua does the
	-- reload (safely) once this text-entry overlay has closed.
	setenv("StarlightSearchReload", 1)
	return #matches
end

-- Open the search keyboard. `wheel` is ScreenSelectMusic's MusicWheel; `onDone`
-- (optional) runs after OK or Cancel.
function M.Prompt(wheel, onDone)
	SCREENMAN:AddNewScreenToTop("ScreenTextEntry")
	SCREENMAN:GetTopScreen():Load({
		Question = "Search songs (title / artist):",
		InitialAnswer = "",   -- always start empty
		MaxInputLength = 100,
		OnOK = function(answer)
			M.Apply(wheel, answer)
			if onDone then onDone() end
		end,
		OnCancel = function()
			if onDone then onDone() end
		end,
	})
end

return M
