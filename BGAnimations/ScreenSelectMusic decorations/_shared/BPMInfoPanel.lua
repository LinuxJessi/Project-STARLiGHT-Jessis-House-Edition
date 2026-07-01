-- Shared song-info panel, used on both the song wheel and the difficulty
-- ("cover") screen so they stay identical. Two sections:
--   BPM      - duration-weighted avg / true range / max + a speed/variability tag
--   SENSORY  - a data-driven difficulty rating (ChartSensory in Scripts/00 AInit.lua)
--              computed from the actual chart: peak NPS, density, jump load and
--              gimmicks -- NOT the author's foot meter, which is inconsistent
--              across user charts. Shows the current chart's NPS + note-colour /
--              gimmick mix, and the "jump" as the sensory score across every
--              difficulty (current bracketed) so the deltas are real difficulty.
-- The CALLER handles position and show/hide (wrap this in an outer ActorFrame).

local DIFF_ORDER = {
	"Difficulty_Beginner", "Difficulty_Easy", "Difficulty_Medium",
	"Difficulty_Hard", "Difficulty_Challenge", "Difficulty_Edit",
}
local CLEAR = { "Label", "Big", "AvgTag", "Range", "Max", "Rating",
	"Level", "Sensory", "NPS", "Mix", "Jump" }

local function colorMix(colors)
	if not colors then return nil end
	if colors.techPct >= 0.5 then return "16TH-heavy"
	elseif colors.techPct >= 0.25 then return "16th bursts"
	elseif colors.finest >= 12 then return "some 12/16ths"
	else return "mostly 4/8ths" end
end

local function Refresh(s)
	local c = s:GetChildren()
	local song = GAMESTATE:GetCurrentSong()
	if not song then
		for _, n in ipairs(CLEAR) do if c[n] then c[n]:settext("") end end
		return
	end
	local pn = GAMESTATE:GetMasterPlayerNumber()
	local curSteps = GAMESTATE:GetCurrentSteps(pn)

	-- BPM section
	local est = EstimateSongBPM(song, curSteps)
	local lo, hi = math.floor(est.min + 0.5), math.floor(est.max + 0.5)
	c.Label:settext("BPM")
	c.AvgTag:settext("AVG")
	c.Big:settext(string.format("%03d", est.average))
	if est.constant then
		c.Range:settext(string.format("RANGE  %03d", est.average))
	else
		c.Range:settext(string.format("RANGE  %03d - %03d", lo, hi))
	end
	c.Max:settext(string.format("MAX    %03d", hi))
	local speed, speedColor = BPMSpeedTier(est.dominant)
	c.Rating:settext(speed .. " / " .. BPMVariability(est))
	c.Rating:diffuse(speedColor)

	-- Sensory difficulty section
	local style = GAMESTATE:GetCurrentStyle()
	local st = style and style:GetStepsType()
	local curDiff = curSteps and curSteps:GetDifficulty()
	if not (st and curDiff and curSteps) then
		c.Level:settext(""); c.Sensory:settext(""); c.NPS:settext(""); c.Mix:settext(""); c.Jump:settext("")
		return
	end

	c.Level:settext(THEME:GetString("CustomDifficulty", ToEnumShortString(curDiff))
		.. "  (foot " .. (curSteps:GetMeter() or 0) .. ")")
	c.Level:diffuse(CustomDifficultyToColor(curDiff))

	local sen = ChartSensory(curSteps, pn)
	if sen then
		c.Sensory:settext("SENSORY  " .. sen.score)
		c.Sensory:diffuse(SensoryTier(sen.score))
		c.NPS:settext(string.format("NPS %.1f / %.1f pk", sen.avgNPS, sen.peakNPS))
		local parts = {}
		local mix = colorMix(ChartNoteColors(curSteps))
		if mix then parts[#parts + 1] = mix end
		if #sen.gimmicks > 0 then parts[#parts + 1] = table.concat(sen.gimmicks, " ") end
		c.Mix:settext(table.concat(parts, "  "))
	else
		c.Sensory:settext(""); c.NPS:settext(""); c.Mix:settext("")
	end

	-- Jump ladder: the SENSORY score of every difficulty (current bracketed),
	-- so the jumps between them reflect real difficulty, not the foot rating.
	local rungs = {}
	for _, d in ipairs(DIFF_ORDER) do
		if song:HasStepsTypeAndDifficulty(st, d) then
			local dsen = ChartSensory(song:GetOneSteps(st, d), pn)
			local sc = dsen and dsen.score or 0
			rungs[#rungs + 1] = (d == curDiff) and ("[" .. sc .. "]") or tostring(sc)
		end
	end
	c.Jump:settext(table.concat(rungs, " > "))
end

return Def.ActorFrame{
	Name="BPMInfoPanel",
	OnCommand=Refresh,
	CurrentSongChangedMessageCommand=Refresh,
	CurrentStepsP1ChangedMessageCommand=Refresh,
	CurrentStepsP2ChangedMessageCommand=Refresh,
	StartSelectingStepsMessageCommand=Refresh,
	ChangeStepsMessageCommand=Refresh,
	-- BPM section
	Def.BitmapText{ Font="_stagetext", Name="Label",
		InitCommand=function(s) s:zoom(0.55):y(-110):DiffuseAndStroke(color("#dff0ff"),color("0,0.7,1,0.5")) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/46px", Name="Big",
		InitCommand=function(s) s:zoom(0.9):y(-84):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="AvgTag",
		InitCommand=function(s) s:zoom(0.6):xy(54,-78):halign(0):diffuse(Alpha(Color.White,0.6)):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="Range",
		InitCommand=function(s) s:y(-46):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="Max",
		InitCommand=function(s) s:y(-24):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="Rating",
		InitCommand=function(s) s:zoom(0.85):y(-2):strokecolor(Color.Black) end },
	Def.Quad{ Name="Sep1",
		InitCommand=function(s) s:y(15):setsize(200,2):diffuse(Alpha(color("#8ad4ff"),0.5)) end },
	-- Sensory section
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="Level",
		InitCommand=function(s) s:zoom(0.85):y(30):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/25px", Name="Sensory",
		InitCommand=function(s) s:zoom(1.1):y(56):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="NPS",
		InitCommand=function(s) s:zoom(0.9):y(84):strokecolor(Color.Black) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="Mix",
		InitCommand=function(s) s:zoom(0.8):y(104):maxwidth(300):diffuse(Alpha(Color.White,0.75)):strokecolor(Color.Black) end },
	Def.Quad{ Name="Sep2",
		InitCommand=function(s) s:y(122):setsize(200,2):diffuse(Alpha(color("#8ad4ff"),0.5)) end },
	Def.BitmapText{ Font="_avenirnext lt pro bold/20px", Name="Jump",
		InitCommand=function(s) s:zoom(0.9):y(140):maxwidth(260):strokecolor(Color.Black) end },
}
