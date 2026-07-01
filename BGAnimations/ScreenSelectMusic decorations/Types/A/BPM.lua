local LoadingScreen = Var "LoadingScreen"
--smcmd is "screen metrics command", gmcmd is "general metrics command"
--these make it require a little less typing to run useful BPMDisplay related commands
local smcmd, gmcmd
do
	smcmd = function(s, name)
		return (THEME:GetMetric(LoadingScreen, name))(s)
	end
	gmcmd = function(s, name)
		return (THEME:GetMetric("BPMDisplay", name))(s)
	end
end

--The BPM shown here is a duration-weighted estimate computed from the song's
--real timing data (EstimateSongBPM in Scripts/00 AInit.lua), NOT the declared
--#DISPLAYBPM tag. Constant charts show a single number; variable charts stack
--the dominant BPM over the true range (this display is narrow). Songs with a
--random/hidden #DISPLAYBPM now show a real tempo instead of cycling digits.
local function ShowEstimatedBPM(s, song)
	local est = EstimateSongBPM(song)
	if est.constant then
		gmcmd(s, "SetNormalCommand")
		s:aux(est.dominant):settextf("BPM\n%03d", est.dominant)
	else
		gmcmd(s, "SetChangeCommand")
		s:aux(est.dominant):settextf("BPM\n%03d\n%03d-%03d", est.dominant,
			math.floor(est.min + 0.5), math.floor(est.max + 0.5))
	end
	s:GetParent():SetUpdateFunction(nil)
end

return Def.ActorFrame{
	--only ActorFrames and classes based on ActorFrame have update functions, which we need
	Name="SNBPMDisplayHost",
	Def.BitmapText{
		Font="_avenirnext lt pro bold/25px",
		Name="BPMDisplay",
		InitCommand=function(s) s:aux(0):align(0.5,0):zoom(0.65):vertspacing(-5):xy(-10,-14):settext "000"; return gmcmd(s, "SetNoBpmCommand") end,
		CurrentSongChangedMessageCommand = function(s, _)
			local song = GAMESTATE:GetCurrentSong()
			if song then
				ShowEstimatedBPM(s, song)
			else
				gmcmd(s, "SetNoBpmCommand")
				s:aux(0):settext "":GetParent():SetUpdateFunction(nil)
			end
		end
	}
}
