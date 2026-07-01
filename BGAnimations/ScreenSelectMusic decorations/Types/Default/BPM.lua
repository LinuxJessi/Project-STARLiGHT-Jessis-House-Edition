local LoadingScreen = Var "LoadingScreen"
local hal = ({...})[1]
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
--#DISPLAYBPM tag. Constant charts show a single number; variable charts show
--the dominant BPM with the true range beside it. This also means songs with a
--random/hidden #DISPLAYBPM now display a real tempo instead of cycling digits.
local function ShowEstimatedBPM(s, song)
	local est = EstimateSongBPM(song)
	if est.constant then
		gmcmd(s, "SetNormalCommand")
		s:settextf("BPM %03d", est.dominant)
	else
		gmcmd(s, "SetChangeCommand")
		s:settextf("BPM %03d (%03d-%03d)", est.dominant,
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
		InitCommand=function(s) s:aux(0):settext "000":strokecolor(Alpha(Color.Black,0.5)):halign(hal); return gmcmd(s, "SetNoBpmCommand") end,
		OnCommand=function(s) return smcmd(s, "BPMDisplayOnCommand") end,
		OffCommand=function(s) return smcmd(s, "BPMDisplayOffCommand") end,
		CurrentSongChangedMessageCommand = function(s, _)
			local song = GAMESTATE:GetCurrentSong()
			if song then
				ShowEstimatedBPM(s, song)
			else
				gmcmd(s, "SetNoBpmCommand")
				s:settext "":GetParent():SetUpdateFunction(nil)
			end
		end
	}
}
