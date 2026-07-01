-- Dim backdrop behind the song-search keyboard (ScreenTextEntry) so the prompt
-- and typed text are readable over the bright song wheel. Drawn in the underlay
-- layer: over the wheel showing through, under the text-entry prompt/answer.
return Def.ActorFrame{
	-- Full-screen dim.
	Def.Quad{
		InitCommand=function(s) s:Center():setsize(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(Color.Black):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.15):diffusealpha(0.72) end,
		OffCommand=function(s) s:linear(0.1):diffusealpha(0) end,
	},
	-- Framed panel behind the question / answer.
	Def.Quad{
		InitCommand=function(s) s:Center():setsize(SCREEN_WIDTH-120, 220):diffuse(color("#0a1b26")):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.15):diffusealpha(0.9) end,
		OffCommand=function(s) s:linear(0.1):diffusealpha(0) end,
	},
	-- Cyan accent lines top & bottom of the panel.
	Def.Quad{
		InitCommand=function(s) s:Center():setsize(SCREEN_WIDTH-120, 3):addy(-110):diffuse(color("#01a2df")):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.15):diffusealpha(0.9) end,
		OffCommand=function(s) s:linear(0.1):diffusealpha(0) end,
	},
	Def.Quad{
		InitCommand=function(s) s:Center():setsize(SCREEN_WIDTH-120, 3):addy(110):diffuse(color("#01a2df")):diffusealpha(0) end,
		OnCommand=function(s) s:linear(0.15):diffusealpha(0.9) end,
		OffCommand=function(s) s:linear(0.1):diffusealpha(0) end,
	},
}
