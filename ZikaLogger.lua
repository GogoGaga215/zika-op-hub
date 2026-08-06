local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local lp = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local function GetChar() return lp.Character end
local function GetRoot() return GetChar() and (GetChar():FindFirstChild("HumanoidRootPart") or GetChar():FindFirstChild("Torso")) end
local function GetHum() return GetChar() and GetChar():FindFirstChildOfClass("Humanoid") end

local function getFullPath(inst)
	local parts = {}
	local cur = inst
	while cur and cur ~= game do
		table.insert(parts, 1, cur.Name)
		cur = cur.Parent
	end
	return table.concat(parts, ".")
end

local function fmtDuration(d)
	if not d or d ~= d or d <= 0 then return "0:00" end
	if d >= 3600 then
		return string.format("%dh %02dm", math.floor(d / 3600), math.floor((d % 3600) / 60))
	end
	return string.format("%d:%02d", math.floor(d / 60), math.floor(d % 60))
end

local function extractId(s)
	return tostring(s.SoundId):match("%d+") or ""
end

local function extractImgId(url)
	if not url or url == "" then return "" end
	local str = tostring(url)
	local id = str:match("rbxassetid://(%d+)")
	if id and id ~= "0" then return id end
	id = str:match("^(%d+)$")
	if id and id ~= "0" then return id end
	return ""
end

local function getCategory(s)
	local dur = s.TimeLength or 0
	if dur >= 25 then return "Music" end
	if dur > 0 then return "SFX" end
	local p = getFullPath(s):lower()
	local n = s.Name:lower()
	if p:find("music") or p:find("ambient") or p:find("song") or p:find("ost")
	or n:find("music") or n:find("theme") or n:find("song") or n:find("bgm") or n:find("ost")
	or s.Looped == true then
		return "Music"
	end
	return "SFX"
end

local function wsPath(inst)
	local fp = getFullPath(inst)
	local after = fp:match("^[Ww]orkspace%.(.+)$")
	return after and ("workspace." .. after) or ("workspace." .. fp)
end

local sg = Instance.new("ScreenGui")
sg.Name = "ZikaLogger"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn then syn.protect_gui(sg) end end)
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = lp.PlayerGui end

local C = {
	BG    = Color3.fromRGB(18, 14, 32),
	PANEL = Color3.fromRGB(28, 22, 48),
	SIDE  = Color3.fromRGB(24, 18, 42),
	A1    = Color3.fromRGB(138, 75, 255),
	A2    = Color3.fromRGB(75, 120, 255),
	A3    = Color3.fromRGB(0, 220, 235),
	TXT   = Color3.fromRGB(240, 238, 255),
	SUB   = Color3.fromRGB(145, 135, 175),
	SEL   = Color3.fromRGB(65, 40, 115),
	HOV   = Color3.fromRGB(38, 30, 64),
	BDR   = Color3.fromRGB(80, 60, 140),
	GRN   = Color3.fromRGB(40, 185, 85),
	ORG   = Color3.fromRGB(225, 115, 35),
	BLU   = Color3.fromRGB(45, 105, 235),
	RED   = Color3.fromRGB(220, 55, 65),
	CODE  = Color3.fromRGB(12, 8, 24),
}

local W, H, TH, LSW, RSW = 760, 430, 44, 128, 178

local mf = Instance.new("Frame", sg)
mf.Name = "Main"
mf.Size = UDim2.new(0, W, 0, H)
mf.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
mf.BackgroundColor3 = C.BG
mf.BorderSizePixel = 0
mf.ClipsDescendants = true
Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 18)
local mfStroke = Instance.new("UIStroke", mf)
mfStroke.Color = C.A1
mfStroke.Thickness = 2

local tbar = Instance.new("Frame", mf)
tbar.Size = UDim2.new(1, 0, 0, TH)
tbar.BackgroundColor3 = C.PANEL
tbar.BorderSizePixel = 0
tbar.ZIndex = 10
Instance.new("UICorner", tbar).CornerRadius = UDim.new(0, 18)

local function tblabel(x, w, txt, col, sz, font, xa)
	local l = Instance.new("TextLabel", tbar)
	l.Size = UDim2.new(0, w, 1, 0)
	l.Position = UDim2.new(0, x, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = col or C.TXT
	l.TextSize = sz or 13
	l.Font = font or Enum.Font.GothamBold
	l.TextXAlignment = xa or Enum.TextXAlignment.Left
	l.ZIndex = 11
	return l
end

tblabel(16, 108, "Zika Logger", C.TXT, 15, Enum.Font.GothamBold)

local tabAudioBtn = Instance.new("TextButton", tbar)
tabAudioBtn.Size = UDim2.new(0, 74, 0, 26)
tabAudioBtn.Position = UDim2.new(0, 128, 0.5, -13)
tabAudioBtn.BackgroundColor3 = C.A1
tabAudioBtn.Text = "Audio"
tabAudioBtn.TextColor3 = C.TXT
tabAudioBtn.TextSize = 11
tabAudioBtn.Font = Enum.Font.GothamBold
tabAudioBtn.BorderSizePixel = 0
tabAudioBtn.ZIndex = 12
Instance.new("UICorner", tabAudioBtn).CornerRadius = UDim.new(1, 0)

local tabImageBtn = Instance.new("TextButton", tbar)
tabImageBtn.Size = UDim2.new(0, 74, 0, 26)
tabImageBtn.Position = UDim2.new(0, 208, 0.5, -13)
tabImageBtn.BackgroundColor3 = C.PANEL
tabImageBtn.Text = "Image"
tabImageBtn.TextColor3 = C.TXT
tabImageBtn.TextSize = 11
tabImageBtn.Font = Enum.Font.GothamBold
tabImageBtn.BorderSizePixel = 0
tabImageBtn.ZIndex = 12
Instance.new("UICorner", tabImageBtn).CornerRadius = UDim.new(1, 0)

local tabOthersBtn = Instance.new("TextButton", tbar)
tabOthersBtn.Size = UDim2.new(0, 74, 0, 26)
tabOthersBtn.Position = UDim2.new(0, 288, 0.5, -13)
tabOthersBtn.BackgroundColor3 = C.PANEL
tabOthersBtn.Text = "Others"
tabOthersBtn.TextColor3 = C.TXT
tabOthersBtn.TextSize = 11
tabOthersBtn.Font = Enum.Font.GothamBold
tabOthersBtn.BorderSizePixel = 0
tabOthersBtn.ZIndex = 12
Instance.new("UICorner", tabOthersBtn).CornerRadius = UDim.new(1, 0)

local statusL = tblabel(370, 188, "", C.A3, 10, Enum.Font.Code)
statusL.TextTruncate = Enum.TextTruncate.AtEnd
local countL = tblabel(576, 96, "0 found", C.SUB, 11, Enum.Font.Gotham, Enum.TextXAlignment.Right)

local minBtn = Instance.new("TextButton", tbar)
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(0, 720, 0.5, -13)
minBtn.BackgroundColor3 = C.A1
minBtn.Text = "-"
minBtn.TextColor3 = C.TXT
minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.ZIndex = 12
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(1, 0)

local body = Instance.new("Frame", mf)
body.Size = UDim2.new(1, 0, 1, -TH)
body.Position = UDim2.new(0, 0, 0, TH)
body.BackgroundTransparency = 1

-- ================================================================
-- AUDIO BODY
-- ================================================================
local audioBody = Instance.new("Frame", body)
audioBody.Size = UDim2.new(1, 0, 1, 0)
audioBody.BackgroundTransparency = 1
audioBody.Visible = true

local ls = Instance.new("Frame", audioBody)
ls.Size = UDim2.new(0, LSW, 1, 0)
ls.BackgroundColor3 = C.SIDE
ls.BorderSizePixel = 0
Instance.new("UICorner", ls).CornerRadius = UDim.new(0, 12)
local lsp = Instance.new("UIPadding", ls)
lsp.PaddingTop = UDim.new(0, 10)
lsp.PaddingLeft = UDim.new(0, 8)
lsp.PaddingRight = UDim.new(0, 8)
local lsl = Instance.new("UIListLayout", ls)
lsl.SortOrder = Enum.SortOrder.LayoutOrder
lsl.Padding = UDim.new(0, 6)

local function lshdr(txt, lo)
	local l = Instance.new("TextLabel", ls)
	l.Size = UDim2.new(1, 0, 0, 14)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = C.SUB
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = lo
end

local function lsbtn(txt, lo, bg)
	local b = Instance.new("TextButton", ls)
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = bg or C.PANEL
	b.Text = txt
	b.TextColor3 = C.TXT
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.LayoutOrder = lo
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	return b
end

lshdr("FILTER", 1)
local fAll   = lsbtn("All Audios", 2, C.A1)
local fMusic = lsbtn("Music", 3)
local fSFX   = lsbtn("SFX", 4)
local lsSep  = Instance.new("Frame", ls)
lsSep.Size = UDim2.new(1, 0, 0, 1)
lsSep.BackgroundColor3 = C.BDR
lsSep.BorderSizePixel = 0
lsSep.LayoutOrder = 5
lshdr("TOOLS", 6)
local refreshBtn = lsbtn("Refresh List", 7, C.A2)

local ca = Instance.new("Frame", audioBody)
ca.Size = UDim2.new(1, -(LSW + RSW), 1, 0)
ca.Position = UDim2.new(0, LSW, 0, 0)
ca.BackgroundColor3 = C.BG
ca.BorderSizePixel = 0

local sbFrame = Instance.new("Frame", ca)
sbFrame.Size = UDim2.new(1, -12, 0, 30)
sbFrame.Position = UDim2.new(0, 6, 0, 6)
sbFrame.BackgroundColor3 = C.PANEL
sbFrame.BorderSizePixel = 0
Instance.new("UICorner", sbFrame).CornerRadius = UDim.new(1, 0)
local sbBox = Instance.new("TextBox", sbFrame)
sbBox.Size = UDim2.new(1, -20, 1, 0)
sbBox.Position = UDim2.new(0, 10, 0, 0)
sbBox.BackgroundTransparency = 1
sbBox.Text = ""
sbBox.PlaceholderText = "Search name or ID..."
sbBox.TextColor3 = C.TXT
sbBox.PlaceholderColor3 = C.SUB
sbBox.TextSize = 11
sbBox.Font = Enum.Font.Gotham
sbBox.TextXAlignment = Enum.TextXAlignment.Left
sbBox.ClearTextOnFocus = false

local hdRow = Instance.new("Frame", ca)
hdRow.Size = UDim2.new(1, 0, 0, 24)
hdRow.Position = UDim2.new(0, 0, 0, 40)
hdRow.BackgroundColor3 = C.PANEL
hdRow.BorderSizePixel = 0

local function hcol(txt, xp, wp)
	local l = Instance.new("TextLabel", hdRow)
	l.Size = UDim2.new(wp, -4, 1, 0)
	l.Position = UDim2.new(xp, 8, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = C.SUB
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
end

hcol("NAME", 0, 0.37)
hcol("ASSET ID", 0.37, 0.31)
hcol("DURATION", 0.68, 0.16)
hcol("PATH", 0.84, 0.16)

local sf = Instance.new("ScrollingFrame", ca)
sf.Size = UDim2.new(1, 0, 1, -64)
sf.Position = UDim2.new(0, 0, 0, 64)
sf.BackgroundTransparency = 1
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 4
sf.ScrollBarImageColor3 = C.A1
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
local sfl = Instance.new("UIListLayout", sf)
sfl.SortOrder = Enum.SortOrder.LayoutOrder
sfl.Padding = UDim.new(0, 2)

local rs = Instance.new("Frame", audioBody)
rs.Size = UDim2.new(0, RSW, 1, 0)
rs.Position = UDim2.new(1, -RSW, 0, 0)
rs.BackgroundColor3 = C.SIDE
rs.BorderSizePixel = 0
rs.ClipsDescendants = true
Instance.new("UICorner", rs).CornerRadius = UDim.new(0, 12)
local rsp = Instance.new("UIPadding", rs)
rsp.PaddingTop = UDim.new(0, 10)
rsp.PaddingLeft = UDim.new(0, 8)
rsp.PaddingRight = UDim.new(0, 8)
rsp.PaddingBottom = UDim.new(0, 8)
local rsl = Instance.new("UIListLayout", rs)
rsl.SortOrder = Enum.SortOrder.LayoutOrder
rsl.Padding = UDim.new(0, 5)

local function rshdr(txt, lo)
	local l = Instance.new("TextLabel", rs)
	l.Size = UDim2.new(1, 0, 0, 13)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = C.SUB
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = lo
end

local function rsfield(hdr, lo)
	local w = Instance.new("Frame", rs)
	w.Size = UDim2.new(1, 0, 0, 0)
	w.AutomaticSize = Enum.AutomaticSize.Y
	w.BackgroundTransparency = 1
	w.LayoutOrder = lo
	local h = Instance.new("TextLabel", w)
	h.Size = UDim2.new(1, 0, 0, 11)
	h.BackgroundTransparency = 1
	h.Text = hdr
	h.TextColor3 = C.SUB
	h.TextSize = 9
	h.Font = Enum.Font.GothamBold
	h.TextXAlignment = Enum.TextXAlignment.Left
	local v = Instance.new("TextLabel", w)
	v.Size = UDim2.new(1, 0, 0, 0)
	v.AutomaticSize = Enum.AutomaticSize.Y
	v.Position = UDim2.new(0, 0, 0, 12)
	v.BackgroundTransparency = 1
	v.Text = "—"
	v.TextColor3 = C.TXT
	v.TextSize = 11
	v.Font = Enum.Font.Gotham
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextWrapped = true
	return v
end

rshdr("SELECTED AUDIO", 1)
local rsName = rsfield("NAME", 2)
local rsId   = rsfield("ASSET ID", 3)
local rsDur  = rsfield("DURATION", 4)
local rsCat  = rsfield("CATEGORY", 5)
rshdr("WORKSPACE PATH", 6)

local wsLbl = Instance.new("TextLabel", rs)
wsLbl.Size = UDim2.new(1, 0, 0, 0)
wsLbl.AutomaticSize = Enum.AutomaticSize.Y
wsLbl.BackgroundColor3 = C.CODE
wsLbl.Text = "workspace.—"
wsLbl.TextColor3 = C.A3
wsLbl.TextSize = 10
wsLbl.Font = Enum.Font.Code
wsLbl.TextXAlignment = Enum.TextXAlignment.Left
wsLbl.TextWrapped = true
wsLbl.LayoutOrder = 7
Instance.new("UICorner", wsLbl).CornerRadius = UDim.new(0, 8)
local wspad = Instance.new("UIPadding", wsLbl)
wspad.PaddingLeft = UDim.new(0, 6)
wspad.PaddingRight = UDim.new(0, 6)
wspad.PaddingTop = UDim.new(0, 4)
wspad.PaddingBottom = UDim.new(0, 4)

rshdr("PATH", 8)
local rsPath = Instance.new("TextLabel", rs)
rsPath.Size = UDim2.new(1, 0, 0, 0)
rsPath.AutomaticSize = Enum.AutomaticSize.Y
rsPath.BackgroundTransparency = 1
rsPath.Text = "—"
rsPath.TextColor3 = C.SUB
rsPath.TextSize = 10
rsPath.Font = Enum.Font.Code
rsPath.TextXAlignment = Enum.TextXAlignment.Left
rsPath.TextWrapped = true
rsPath.LayoutOrder = 9

local rsSep = Instance.new("Frame", rs)
rsSep.Size = UDim2.new(1, 0, 0, 1)
rsSep.BackgroundColor3 = C.BDR
rsSep.BorderSizePixel = 0
rsSep.LayoutOrder = 10

local function rsbtn(txt, lo, col)
	local b = Instance.new("TextButton", rs)
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = col
	b.Text = txt
	b.TextColor3 = C.TXT
	b.TextSize = 10
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.LayoutOrder = lo
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	return b
end

local btnLoop = rsbtn("Loop Play Audio", 11, C.ORG)
local btnPlay = rsbtn("Play Audio", 12, C.GRN)
local btnCopy = rsbtn("Copy Asset Id", 13, C.BLU)

-- ================================================================
-- IMAGE BODY
-- ================================================================
local imageBody = Instance.new("Frame", body)
imageBody.Size = UDim2.new(1, 0, 1, 0)
imageBody.BackgroundTransparency = 1
imageBody.Visible = false

local ils = Instance.new("Frame", imageBody)
ils.Size = UDim2.new(0, LSW, 1, 0)
ils.BackgroundColor3 = C.SIDE
ils.BorderSizePixel = 0
Instance.new("UICorner", ils).CornerRadius = UDim.new(0, 12)
local ilsp = Instance.new("UIPadding", ils)
ilsp.PaddingTop = UDim.new(0, 10)
ilsp.PaddingLeft = UDim.new(0, 8)
ilsp.PaddingRight = UDim.new(0, 8)
local ilsl = Instance.new("UIListLayout", ils)
ilsl.SortOrder = Enum.SortOrder.LayoutOrder
ilsl.Padding = UDim.new(0, 6)

local function ilshdr(txt, lo)
	local l = Instance.new("TextLabel", ils)
	l.Size = UDim2.new(1, 0, 0, 14)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = C.SUB
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = lo
end

local function ilsbtn(txt, lo, bg)
	local b = Instance.new("TextButton", ils)
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = bg or C.PANEL
	b.Text = txt
	b.TextColor3 = C.TXT
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.LayoutOrder = lo
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	return b
end

ilshdr("FILTER", 1)
local ifAll      = ilsbtn("All Images",  2, C.A1)
local ifDecal    = ilsbtn("Decal",       3)
local ifTexture  = ilsbtn("Texture",     4)
local ifImgLabel = ilsbtn("ImageLabel",  5)
local ilsSep     = Instance.new("Frame", ils)
ilsSep.Size = UDim2.new(1, 0, 0, 1)
ilsSep.BackgroundColor3 = C.BDR
ilsSep.BorderSizePixel = 0
ilsSep.LayoutOrder = 6
ilshdr("TOOLS", 7)
local iRefreshBtn = ilsbtn("Refresh List", 8, C.A2)

local ica = Instance.new("Frame", imageBody)
ica.Size = UDim2.new(1, -(LSW + RSW), 1, 0)
ica.Position = UDim2.new(0, LSW, 0, 0)
ica.BackgroundColor3 = C.BG
ica.BorderSizePixel = 0

local isbFrame = Instance.new("Frame", ica)
isbFrame.Size = UDim2.new(1, -12, 0, 30)
isbFrame.Position = UDim2.new(0, 6, 0, 6)
isbFrame.BackgroundColor3 = C.PANEL
isbFrame.BorderSizePixel = 0
Instance.new("UICorner", isbFrame).CornerRadius = UDim.new(1, 0)
local isbBox = Instance.new("TextBox", isbFrame)
isbBox.Size = UDim2.new(1, -20, 1, 0)
isbBox.Position = UDim2.new(0, 10, 0, 0)
isbBox.BackgroundTransparency = 1
isbBox.Text = ""
isbBox.PlaceholderText = "Search name or ID..."
isbBox.TextColor3 = C.TXT
isbBox.PlaceholderColor3 = C.SUB
isbBox.TextSize = 11
isbBox.Font = Enum.Font.Gotham
isbBox.TextXAlignment = Enum.TextXAlignment.Left
isbBox.ClearTextOnFocus = false

local ihdRow = Instance.new("Frame", ica)
ihdRow.Size = UDim2.new(1, 0, 0, 24)
ihdRow.Position = UDim2.new(0, 0, 0, 40)
ihdRow.BackgroundColor3 = C.PANEL
ihdRow.BorderSizePixel = 0

local function ihcol(txt, xp, wp)
	local l = Instance.new("TextLabel", ihdRow)
	l.Size = UDim2.new(wp, -4, 1, 0)
	l.Position = UDim2.new(xp, 8, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = C.SUB
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
end

ihcol("THUMB",    0,    0.10)
ihcol("NAME",     0.10, 0.30)
ihcol("ASSET ID", 0.40, 0.30)
ihcol("TYPE",     0.70, 0.16)
ihcol("PATH",     0.86, 0.14)

local isf = Instance.new("ScrollingFrame", ica)
isf.Size = UDim2.new(1, 0, 1, -64)
isf.Position = UDim2.new(0, 0, 0, 64)
isf.BackgroundTransparency = 1
isf.BorderSizePixel = 0
isf.ScrollBarThickness = 4
isf.ScrollBarImageColor3 = C.A1
isf.CanvasSize = UDim2.new(0, 0, 0, 0)
local isfl = Instance.new("UIListLayout", isf)
isfl.SortOrder = Enum.SortOrder.LayoutOrder
isfl.Padding = UDim.new(0, 2)

local irs = Instance.new("Frame", imageBody)
irs.Size = UDim2.new(0, RSW, 1, 0)
irs.Position = UDim2.new(1, -RSW, 0, 0)
irs.BackgroundColor3 = C.SIDE
irs.BorderSizePixel = 0
irs.ClipsDescendants = true
Instance.new("UICorner", irs).CornerRadius = UDim.new(0, 12)
local irsp = Instance.new("UIPadding", irs)
irsp.PaddingTop = UDim.new(0, 10)
irsp.PaddingLeft = UDim.new(0, 8)
irsp.PaddingRight = UDim.new(0, 8)
irsp.PaddingBottom = UDim.new(0, 8)
local irsl = Instance.new("UIListLayout", irs)
irsl.SortOrder = Enum.SortOrder.LayoutOrder
irsl.Padding = UDim.new(0, 5)

local function irshdr(txt, lo)
	local l = Instance.new("TextLabel", irs)
	l.Size = UDim2.new(1, 0, 0, 13)
	l.BackgroundTransparency = 1
	l.Text = txt
	l.TextColor3 = C.SUB
	l.TextSize = 9
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.LayoutOrder = lo
end

local function irsfield(hdr, lo)
	local w = Instance.new("Frame", irs)
	w.Size = UDim2.new(1, 0, 0, 0)
	w.AutomaticSize = Enum.AutomaticSize.Y
	w.BackgroundTransparency = 1
	w.LayoutOrder = lo
	local h = Instance.new("TextLabel", w)
	h.Size = UDim2.new(1, 0, 0, 11)
	h.BackgroundTransparency = 1
	h.Text = hdr
	h.TextColor3 = C.SUB
	h.TextSize = 9
	h.Font = Enum.Font.GothamBold
	h.TextXAlignment = Enum.TextXAlignment.Left
	local v = Instance.new("TextLabel", w)
	v.Size = UDim2.new(1, 0, 0, 0)
	v.AutomaticSize = Enum.AutomaticSize.Y
	v.Position = UDim2.new(0, 0, 0, 12)
	v.BackgroundTransparency = 1
	v.Text = "—"
	v.TextColor3 = C.TXT
	v.TextSize = 11
	v.Font = Enum.Font.Gotham
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextWrapped = true
	return v
end

irshdr("SELECTED IMAGE", 1)

local iPreviewFrame = Instance.new("Frame", irs)
iPreviewFrame.Size = UDim2.new(1, 0, 0, 132)
iPreviewFrame.BackgroundColor3 = C.CODE
iPreviewFrame.BorderSizePixel = 0
iPreviewFrame.LayoutOrder = 2
Instance.new("UICorner", iPreviewFrame).CornerRadius = UDim.new(0, 8)
local iPreview = Instance.new("ImageLabel", iPreviewFrame)
iPreview.Size = UDim2.new(1, -8, 1, -8)
iPreview.Position = UDim2.new(0, 4, 0, 4)
iPreview.BackgroundTransparency = 1
iPreview.Image = ""
iPreview.ScaleType = Enum.ScaleType.Fit

local irsName = irsfield("NAME", 3)
local irsId   = irsfield("ASSET ID", 4)
local irsType = irsfield("TYPE", 5)

irshdr("PATH", 6)
local irsPath = Instance.new("TextLabel", irs)
irsPath.Size = UDim2.new(1, 0, 0, 0)
irsPath.AutomaticSize = Enum.AutomaticSize.Y
irsPath.BackgroundTransparency = 1
irsPath.Text = "—"
irsPath.TextColor3 = C.SUB
irsPath.TextSize = 10
irsPath.Font = Enum.Font.Code
irsPath.TextXAlignment = Enum.TextXAlignment.Left
irsPath.TextWrapped = true
irsPath.LayoutOrder = 7

local irsSep = Instance.new("Frame", irs)
irsSep.Size = UDim2.new(1, 0, 0, 1)
irsSep.BackgroundColor3 = C.BDR
irsSep.BorderSizePixel = 0
irsSep.LayoutOrder = 8

local function irsbtn(txt, lo, col)
	local b = Instance.new("TextButton", irs)
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = col
	b.Text = txt
	b.TextColor3 = C.TXT
	b.TextSize = 10
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	b.LayoutOrder = lo
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	return b
end

local iCopyBtn = irsbtn("Copy Asset Id", 9, C.BLU)

-- ================================================================
-- OTHERS BODY (ESP COMMANDS)
-- ================================================================
local othersBody = Instance.new("Frame", body)
othersBody.Size = UDim2.new(1, 0, 1, 0)
othersBody.BackgroundTransparency = 1
othersBody.Visible = false

-- Input overlay for name-based ESP commands
local inputOverlay = Instance.new("Frame", mf)
inputOverlay.Size = UDim2.new(1, 0, 1, 0)
inputOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inputOverlay.BackgroundTransparency = 0.5
inputOverlay.ZIndex = 60
inputOverlay.Active = true
inputOverlay.Visible = false
Instance.new("UICorner", inputOverlay).CornerRadius = UDim.new(0, 18)

local ipanel = Instance.new("Frame", inputOverlay)
ipanel.Size = UDim2.new(0, 340, 0, 134)
ipanel.Position = UDim2.new(0.5, -170, 0.5, -67)
ipanel.BackgroundColor3 = C.PANEL
ipanel.BorderSizePixel = 0
ipanel.ZIndex = 61
Instance.new("UICorner", ipanel).CornerRadius = UDim.new(0, 12)
do
	local s = Instance.new("UIStroke", ipanel)
	s.Color = C.A1
	s.Thickness = 1.5
end

local ipTitle = Instance.new("TextLabel", ipanel)
ipTitle.Size = UDim2.new(1, -16, 0, 28)
ipTitle.Position = UDim2.new(0, 8, 0, 6)
ipTitle.BackgroundTransparency = 1
ipTitle.Text = "Enter Value"
ipTitle.TextColor3 = C.TXT
ipTitle.TextSize = 13
ipTitle.Font = Enum.Font.GothamBold
ipTitle.TextXAlignment = Enum.TextXAlignment.Left
ipTitle.ZIndex = 62

local ipBox = Instance.new("TextBox", ipanel)
ipBox.Size = UDim2.new(1, -16, 0, 34)
ipBox.Position = UDim2.new(0, 8, 0, 38)
ipBox.BackgroundColor3 = C.BG
ipBox.Text = ""
ipBox.PlaceholderText = "Type here..."
ipBox.TextColor3 = C.TXT
ipBox.PlaceholderColor3 = C.SUB
ipBox.TextSize = 12
ipBox.Font = Enum.Font.Gotham
ipBox.TextXAlignment = Enum.TextXAlignment.Left
ipBox.ClearTextOnFocus = false
ipBox.BorderSizePixel = 0
ipBox.ZIndex = 62
Instance.new("UICorner", ipBox).CornerRadius = UDim.new(0, 8)
do
	local p = Instance.new("UIPadding", ipBox)
	p.PaddingLeft = UDim.new(0, 8)
end

local ipOk = Instance.new("TextButton", ipanel)
ipOk.Size = UDim2.new(0, 100, 0, 30)
ipOk.Position = UDim2.new(0, 8, 0, 88)
ipOk.BackgroundColor3 = C.GRN
ipOk.Text = "Confirm"
ipOk.TextColor3 = C.TXT
ipOk.TextSize = 12
ipOk.Font = Enum.Font.GothamBold
ipOk.BorderSizePixel = 0
ipOk.ZIndex = 62
Instance.new("UICorner", ipOk).CornerRadius = UDim.new(1, 0)

local ipNo = Instance.new("TextButton", ipanel)
ipNo.Size = UDim2.new(0, 100, 0, 30)
ipNo.Position = UDim2.new(0, 120, 0, 88)
ipNo.BackgroundColor3 = C.RED
ipNo.Text = "Cancel"
ipNo.TextColor3 = C.TXT
ipNo.TextSize = 12
ipNo.Font = Enum.Font.GothamBold
ipNo.BorderSizePixel = 0
ipNo.ZIndex = 62
Instance.new("UICorner", ipNo).CornerRadius = UDim.new(1, 0)

local ipCb = nil
local function showInput(title, ph, cb)
	ipTitle.Text = title
	ipBox.PlaceholderText = ph or ""
	ipBox.Text = ""
	ipCb = cb
	inputOverlay.Visible = true
	pcall(function() ipBox:CaptureFocus() end)
end
local function hideInput(val)
	inputOverlay.Visible = false
	local c = ipCb
	ipCb = nil
	if c then c(val) end
end
ipOk.MouseButton1Click:Connect(function() hideInput(ipBox.Text) end)
ipNo.MouseButton1Click:Connect(function() hideInput(nil) end)
ipBox.FocusLost:Connect(function(enter) if enter then hideInput(ipBox.Text) end end)

-- Scroll frame
local othersScroll = Instance.new("ScrollingFrame", othersBody)
othersScroll.Size = UDim2.new(1, -40, 1, -40)
othersScroll.Position = UDim2.new(0, 20, 0, 20)
othersScroll.BackgroundTransparency = 1
othersScroll.BorderSizePixel = 0
othersScroll.ScrollBarThickness = 6
othersScroll.ScrollBarImageColor3 = C.A1
othersScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
pcall(function() othersScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y end)

local othersLayout = Instance.new("UIGridLayout", othersScroll)
othersLayout.CellSize = UDim2.new(0, 160, 0, 45)
othersLayout.CellPadding = UDim2.new(0, 15, 0, 15)
othersLayout.SortOrder = Enum.SortOrder.LayoutOrder
othersLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

pcall(function()
	othersLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		pcall(function()
			othersScroll.CanvasSize = UDim2.new(0, 0, 0, othersLayout.AbsoluteContentSize.Y + 16)
		end)
	end)
end)

-- ================================================================
-- ESP SYSTEM
-- ================================================================

-- Object ESP store: tag -> list of {hl, bb}
local objStore = {}

local function clearObjESP(tag)
	for _, d in ipairs(objStore[tag] or {}) do
		pcall(function() if d.hl then d.hl:Destroy() end end)
		pcall(function() if d.bb then d.bb:Destroy() end end)
	end
	objStore[tag] = nil
end

local function applyESP(tag, inst, col, lbl)
	if not objStore[tag] then objStore[tag] = {} end
	local d = {}
	pcall(function()
		local hl = Instance.new("Highlight")
		hl.FillColor = col
		hl.OutlineColor = col
		hl.FillTransparency = 0.6
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee = inst
		hl.Parent = workspace
		d.hl = hl
	end)
	if lbl then
		local anchor
		if inst:IsA("BasePart") then
			anchor = inst
		elseif inst:IsA("Model") then
			anchor = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
		elseif inst.Parent and inst.Parent:IsA("BasePart") then
			anchor = inst.Parent
		end
		if anchor then
			pcall(function()
				local bb = Instance.new("BillboardGui")
				bb.Size = UDim2.new(0, 210, 0, 42)
				bb.StudsOffset = Vector3.new(0, 2.5, 0)
				bb.AlwaysOnTop = true
				bb.Parent = anchor
				local tl = Instance.new("TextLabel", bb)
				tl.Size = UDim2.new(1, 0, 1, 0)
				tl.BackgroundTransparency = 1
				tl.Font = Enum.Font.GothamBold
				tl.TextSize = 11
				tl.TextColor3 = col
				tl.TextStrokeTransparency = 0.3
				tl.TextWrapped = true
				tl.Text = lbl
				d.bb = bb
			end)
		end
	end
	table.insert(objStore[tag], d)
end

local function doObjESP(tag, col, getInstsFn, lblFn)
	clearObjESP(tag)
	local insts = {}
	pcall(function() insts = getInstsFn() end)
	for _, v in ipairs(insts) do
		pcall(function()
			applyESP(tag, v, col, lblFn and lblFn(v) or nil)
		end)
	end
end

-- Workspace scan helpers
local function scanClass(cls)
	local out = {}
	for _, v in ipairs(Workspace:GetDescendants()) do
		pcall(function() if v:IsA(cls) then table.insert(out, v) end end)
	end
	return out
end

local function scanPred(fn)
	local out = {}
	for _, v in ipairs(Workspace:GetDescendants()) do
		pcall(function() if fn(v) then table.insert(out, v) end end)
	end
	return out
end

-- ================================================================
-- PLAYER ESP
-- ================================================================
local pESPData  = {}   -- [player] = {hl, bb, charConn}
local pESPLoop  = nil
local espTMode  = nil  -- nil / "all" / "enemies" / "allies"
local espCMode  = nil  -- nil / "all" / "enemies" / "allies"

local function pCol(p)
	if not lp.Team then return Color3.fromRGB(210, 210, 210) end
	if p.Team == lp.Team then return Color3.fromRGB(60, 240, 100) end
	return Color3.fromRGB(255, 55, 55)
end

local function pEnemy(p) return not lp.Team or p.Team ~= lp.Team end
local function pAlly(p)  return lp.Team ~= nil and p.Team == lp.Team end

local function pWantT(p)
	return espTMode == "all"
		or (espTMode == "enemies" and pEnemy(p))
		or (espTMode == "allies"  and pAlly(p))
end

local function pWantC(p)
	return espCMode == "all"
		or (espCMode == "enemies" and pEnemy(p))
		or (espCMode == "allies"  and pAlly(p))
end

local function pCleanup(p)
	local d = pESPData[p]
	if d then
		pcall(function() if d.hl then d.hl:Destroy() end end)
		pcall(function() if d.bb then d.bb:Destroy() end end)
		pcall(function() if d.charConn then d.charConn:Disconnect() end end)
	end
	pESPData[p] = nil
end

local function pUpdate(p)
	if p == lp then return end
	local wT = pWantT(p)
	local wC = pWantC(p)
	if not wT and not wC then pCleanup(p) return end
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local d = pESPData[p] or {}
	pESPData[p] = d
	local col = pCol(p)

	-- Chams (Highlight)
	if wC and char then
		if not d.hl or not d.hl.Parent then
			pcall(function()
				d.hl = Instance.new("Highlight")
				d.hl.FillColor = col
				d.hl.OutlineColor = col
				d.hl.FillTransparency = 0.55
				d.hl.OutlineTransparency = 0
				d.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				d.hl.Adornee = char
				d.hl.Parent = workspace
			end)
		else
			pcall(function() d.hl.FillColor = col d.hl.OutlineColor = col end)
		end
	elseif not wC then
		pcall(function() if d.hl then d.hl:Destroy() d.hl = nil end end)
	end

	-- Text ESP (BillboardGui)
	if wT and root then
		if not d.bb or not d.bb.Parent then
			pcall(function()
				d.bb = Instance.new("BillboardGui")
				d.bb.Name = "ZikaPESP"
				d.bb.Size = UDim2.new(0, 260, 0, 52)
				d.bb.StudsOffset = Vector3.new(0, 4, 0)
				d.bb.AlwaysOnTop = true
				d.bb.Parent = root
				local tl = Instance.new("TextLabel", d.bb)
				tl.Name = "L"
				tl.Size = UDim2.new(1, 0, 1, 0)
				tl.BackgroundTransparency = 1
				tl.Font = Enum.Font.GothamBold
				tl.TextSize = 12
				tl.TextStrokeTransparency = 0.3
				tl.TextWrapped = true
			end)
		end
		pcall(function()
			local lbl = d.bb and d.bb:FindFirstChild("L")
			if lbl then
				local mr = GetRoot()
				local dist = mr and math.floor((mr.Position - root.Position).Magnitude) or 0
				lbl.TextColor3 = col
				lbl.Text = p.Name .. "\n[" .. (p.Team and p.Team.Name or "None") .. "] " .. dist .. " studs"
			end
		end)
	elseif not wT then
		pcall(function() if d.bb then d.bb:Destroy() d.bb = nil end end)
	end

	if not d.charConn then
		d.charConn = p.CharacterAdded:Connect(function()
			pcall(function() if d.hl then d.hl:Destroy() d.hl = nil end end)
			pcall(function() if d.bb then d.bb:Destroy() d.bb = nil end end)
		end)
	end
end

local function pStartLoop()
	if pESPLoop then return end
	pESPLoop = RunService.RenderStepped:Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function() pUpdate(p) end)
		end
	end)
end

local function pCheckStop()
	if not espTMode and not espCMode then
		if pESPLoop then pESPLoop:Disconnect() pESPLoop = nil end
		local toClean = {}
		for p in pairs(pESPData) do table.insert(toClean, p) end
		for _, p in ipairs(toClean) do pCleanup(p) end
	end
end

Players.PlayerRemoving:Connect(function(p) pCleanup(p) end)

-- ================================================================
-- NPC ESP
-- ================================================================
local npcESPLoop = nil

local function enableNPCESP()
	if npcESPLoop then return end
	npcESPLoop = RunService.RenderStepped:Connect(function()
		for _, v in ipairs(Workspace:GetDescendants()) do
			pcall(function()
				if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
					and not Players:GetPlayerFromCharacter(v) then
					local root = v:FindFirstChild("HumanoidRootPart")
						or v:FindFirstChild("Torso")
						or v:FindFirstChild("Head")
					if not root then return end
					if not root:FindFirstChild("ZikaNPCESP") then
						local bb = Instance.new("BillboardGui")
						bb.Name = "ZikaNPCESP"
						bb.Size = UDim2.new(0, 230, 0, 44)
						bb.StudsOffset = Vector3.new(0, 3.5, 0)
						bb.AlwaysOnTop = true
						bb.Parent = root
						local tl = Instance.new("TextLabel", bb)
						tl.Size = UDim2.new(1, 0, 1, 0)
						tl.BackgroundTransparency = 1
						tl.Font = Enum.Font.GothamBold
						tl.TextSize = 12
						tl.TextStrokeTransparency = 0.35
						tl.TextColor3 = Color3.fromRGB(255, 170, 0)
						tl.TextWrapped = true
					end
					local bb = root:FindFirstChild("ZikaNPCESP")
					if bb then
						local lbl = bb:FindFirstChildOfClass("TextLabel")
						if lbl then
							local mr = GetRoot()
							local dist = mr and math.floor((mr.Position - root.Position).Magnitude) or 0
							lbl.Text = "[NPC] " .. v.Name .. " | " .. dist .. " studs"
						end
					end
				end
			end)
		end
	end)
end

local function disableNPCESP()
	if npcESPLoop then npcESPLoop:Disconnect() npcESPLoop = nil end
	for _, v in ipairs(Workspace:GetDescendants()) do
		if v.Name == "ZikaNPCESP" then pcall(function() v:Destroy() end) end
	end
end

-- ================================================================
-- ESP LOCATOR (Drawing arrows for off-screen players)
-- ================================================================
local locDrawings = {}
local locLoop     = nil

local function clearLocDraw()
	for _, d in ipairs(locDrawings) do pcall(function() d:Remove() end) end
	locDrawings = {}
end

local function enableLocator()
	if locLoop then return end
	locLoop = RunService.RenderStepped:Connect(function()
		clearLocDraw()
		local vp = Camera.ViewportSize
		local cx, cy = vp.X / 2, vp.Y / 2
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= lp then
				pcall(function()
					local char = p.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if not root then return end
					local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
					if onScreen and pos.Z > 0 then return end
					local dx, dy = pos.X - cx, pos.Y - cy
					local len = math.sqrt(dx * dx + dy * dy)
					if len == 0 then return end
					dx, dy = dx / len, dy / len
					local mg = 32
					local ex, ey
					if math.abs(dx) < 1e-5 then
						ex = cx
						ey = dy > 0 and vp.Y - mg or mg
					elseif math.abs(dy) < 1e-5 then
						ex = dx > 0 and vp.X - mg or mg
						ey = cy
					else
						local tx = ((dx > 0 and vp.X - mg or mg) - cx) / dx
						local ty = ((dy > 0 and vp.Y - mg or mg) - cy) / dy
						local t  = math.min(tx, ty)
						ex = cx + dx * t
						ey = cy + dy * t
					end
					ex = math.clamp(ex, mg, vp.X - mg)
					ey = math.clamp(ey, mg, vp.Y - mg)
					local ang = math.atan2(dy, dx)
					local col = pCol(p)
					local tri = Drawing.new("Triangle")
					tri.PointA   = Vector2.new(ex + math.cos(ang) * 14,       ey + math.sin(ang) * 14)
					tri.PointB   = Vector2.new(ex + math.cos(ang + 2.2) * 9,  ey + math.sin(ang + 2.2) * 9)
					tri.PointC   = Vector2.new(ex + math.cos(ang - 2.2) * 9,  ey + math.sin(ang - 2.2) * 9)
					tri.Color    = col
					tri.Filled   = true
					tri.Visible  = true
					table.insert(locDrawings, tri)
					local txt = Drawing.new("Text")
					txt.Position = Vector2.new(ex - 30, ey + 17)
					txt.Size     = 13
					txt.Text     = p.Name
					txt.Color    = col
					txt.Outline  = true
					txt.Visible  = true
					table.insert(locDrawings, txt)
				end)
			end
		end
	end)
end

local function disableLocator()
	if locLoop then locLoop:Disconnect() locLoop = nil end
	clearLocDraw()
end

-- ================================================================
-- BUTTON FACTORY
-- ================================================================

local function newBtn(label, col)
	local b = Instance.new("TextButton", othersScroll)
	b.BackgroundColor3 = col or C.BLU
	b.Text = label
	b.TextColor3 = C.TXT
	b.TextSize = 11
	b.Font = Enum.Font.GothamBold
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

-- Simple toggle button
local function mkToggle(label, onCb, offCb)
	local b = newBtn(label .. ": OFF", C.RED)
	local on = false
	b.MouseButton1Click:Connect(function()
		on = not on
		b.BackgroundColor3 = on and C.GRN or C.RED
		b.Text = label .. (on and ": ON" or ": OFF")
		if on then onCb(b) else offCb(b) end
	end)
	return b
end

-- Exclusive group: only one button ON at a time
-- setCb(mode) called with the active mode string, or nil when all off
-- Returns forceOff() to programmatically reset the whole group visually
local function mkExGroup(labels, modes, setCb)
	local entries = {}
	local active  = nil

	local function forceOff()
		if active then
			active.btn.BackgroundColor3 = C.RED
			active.btn.Text = active.label .. ": OFF"
			active = nil
		end
	end

	for i, label in ipairs(labels) do
		local mode = modes[i]
		local b = newBtn(label .. ": OFF", C.RED)
		local e = {btn = b, label = label, mode = mode}
		table.insert(entries, e)
		b.MouseButton1Click:Connect(function()
			if active == e then
				forceOff()
				setCb(nil)
			else
				if active then
					active.btn.BackgroundColor3 = C.RED
					active.btn.Text = active.label .. ": OFF"
				end
				b.BackgroundColor3 = C.GRN
				b.Text = label .. ": ON"
				active = e
				setCb(mode)
			end
		end)
	end

	return entries, forceOff
end

-- Object ESP toggle (one-time scan)
local function mkObjToggle(label, tag, col, getInstsFn, lblFn)
	return mkToggle(label,
		function() doObjESP(tag, col, getInstsFn, lblFn) end,
		function() clearObjESP(tag) end
	)
end

-- Input-based ESP toggle: opens dialog on enable, clears on disable
local function mkInputToggle(label, title, ph, tag, col, buildInstsFn, buildLblFn)
	local b = newBtn(label .. ": OFF", C.RED)
	local on = false
	b.MouseButton1Click:Connect(function()
		if on then
			on = false
			b.BackgroundColor3 = C.RED
			b.Text = label .. ": OFF"
			clearObjESP(tag)
		else
			showInput(title, ph, function(val)
				if not val or val:gsub("%s+", "") == "" then return end
				on = true
				b.BackgroundColor3 = C.GRN
				b.Text = label .. ": ON"
				doObjESP(tag, col,
					function() return buildInstsFn(val) end,
					function(v) return buildLblFn and buildLblFn(v, val) or v.Name end
				)
			end)
		end
	end)
	return b
end

-- ================================================================
-- CREATE BUTTONS
-- ================================================================

-- === FLY ===
do
	local flySpeed = 50
	local bodyVel, bodyGyro, flyLoop
	mkToggle("Fly", function()
		local root = GetRoot()
		local hum  = GetHum()
		if not root or not hum then return end
		pcall(function() if bodyVel  then bodyVel:Destroy()  end end)
		pcall(function() if bodyGyro then bodyGyro:Destroy() end end)
		pcall(function()
			bodyVel = Instance.new("BodyVelocity")
			bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			bodyVel.Velocity = Vector3.new(0, 0, 0)
			bodyVel.Parent   = root
		end)
		pcall(function()
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			bodyGyro.P      = 9e4
			bodyGyro.CFrame = root.CFrame
			bodyGyro.Parent = root
		end)
		flyLoop = RunService.RenderStepped:Connect(function()
			if not GetHum() or not GetRoot() or not bodyVel or not bodyGyro then return end
			GetHum().PlatformStand = true
			local moveDir = GetHum().MoveDirection
			pcall(function()
				bodyGyro.CFrame = Camera.CFrame
				if moveDir.Magnitude > 0 then
					local cam = Camera.CFrame
					local rel = cam:VectorToObjectSpace(moveDir)
					local dir = cam.LookVector * (-rel.Z) + cam.RightVector * rel.X
					bodyVel.Velocity = dir.Unit * flySpeed
				else
					bodyVel.Velocity = Vector3.new(0, 0, 0)
				end
			end)
		end)
	end, function()
		if flyLoop  then flyLoop:Disconnect()   flyLoop  = nil end
		if bodyVel  then bodyVel:Destroy()       bodyVel  = nil end
		if bodyGyro then bodyGyro:Destroy()      bodyGyro = nil end
		if GetHum() then GetHum().PlatformStand = false end
	end)
end

-- === PLAYER TEXT ESP (exclusive group) ===
local _, espTForceOff = mkExGroup(
	{"ESP All", "ESP Enemies", "ESP Allies"},
	{"all",     "enemies",     "allies"},
	function(mode)
		espTMode = mode
		if mode then pStartLoop() else pCheckStop() end
	end
)

-- === CHAMS (Highlight, exclusive group) ===
local _, espCForceOff = mkExGroup(
	{"Chams All", "Chams Enemy", "Chams Allies"},
	{"all",       "enemies",     "allies"},
	function(mode)
		espCMode = mode
		if mode then pStartLoop() else pCheckStop() end
	end
)

-- === UN-ESP ALL ===
do
	local b = newBtn("Un-ESP All", C.ORG)
	b.MouseButton1Click:Connect(function()
		espTMode = nil
		espCMode = nil
		espTForceOff()
		espCForceOff()
		pCheckStop()
	end)
end

-- === NPC ESP ===
mkToggle("NPC ESP",
	function() enableNPCESP() end,
	function() disableNPCESP() end
)

-- === OBJECT ESP TOGGLES ===

-- Touch ESP: highlight parts that have a TouchTransmitter
mkObjToggle("Touch ESP", "touch", Color3.fromRGB(0, 220, 235),
	function()
		return scanPred(function(v)
			return v:IsA("BasePart") and v:FindFirstChildOfClass("TouchTransmitter")
		end)
	end,
	function(v) return "[Touch] " .. v.Name end
)

-- Proximity ESP
mkObjToggle("Prox ESP", "prox", Color3.fromRGB(138, 75, 255),
	function()
		return scanPred(function(v)
			return (v:IsA("BasePart") or v:IsA("Model"))
				and v:FindFirstChildOfClass("ProximityPrompt")
		end)
	end,
	function(v)
		local pp = v:FindFirstChildOfClass("ProximityPrompt")
		return "[Prox] " .. (pp and pp.ActionText ~= "" and pp.ActionText or v.Name)
	end
)

-- Click ESP: parts with ClickDetectors
mkObjToggle("Click ESP", "click", Color3.fromRGB(255, 200, 0),
	function()
		return scanPred(function(v)
			return v:IsA("BasePart") and v:FindFirstChildOfClass("ClickDetector")
		end)
	end,
	function(v) return "[Click] " .. v.Name end
)

-- Item ESP: dropped Tools (not inside a player character)
mkObjToggle("Item ESP", "item", Color3.fromRGB(0, 200, 255),
	function()
		return scanPred(function(v)
			if not v:IsA("Tool") then return false end
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character and p.Character:IsAncestorOf(v) then return false end
			end
			return true
		end)
	end,
	function(v) return "[Tool] " .. v.Name end
)

-- Seat ESP
mkObjToggle("Seat ESP", "seat", Color3.fromRGB(60, 240, 100),
	function() return scanClass("Seat") end,
	function(v) return "[Seat] " .. v.Name end
)

-- VehicleSeat ESP
mkObjToggle("V.Seat ESP", "vseat", Color3.fromRGB(100, 200, 255),
	function() return scanClass("VehicleSeat") end,
	function(v) return "[VSeat] " .. v.Name end
)

-- Unanchored parts (no label — too many instances)
mkObjToggle("Unanchored", "unanchor", Color3.fromRGB(255, 100, 200),
	function()
		return scanPred(function(v) return v:IsA("BasePart") and not v.Anchored end)
	end,
	nil
)

-- CanCollide = true parts (no label)
mkObjToggle("Collision", "coll", Color3.fromRGB(200, 200, 50),
	function()
		return scanPred(function(v) return v:IsA("BasePart") and v.CanCollide end)
	end,
	nil
)

-- CanCollide = false parts (no label)
mkObjToggle("No-Coll ESP", "nocoll", Color3.fromRGB(50, 200, 200),
	function()
		return scanPred(function(v) return v:IsA("BasePart") and not v.CanCollide end)
	end,
	nil
)

-- === INPUT-BASED ESP TOGGLES ===

-- Part ESP — exact names, comma-separated  e.g. "Part, Floor, Wall, Car"
mkInputToggle("Part ESP", "Part ESP — Names (comma-sep)", "Part, Floor, Wall, Car ...",
	"part", Color3.fromRGB(255, 140, 60),
	function(input)
		local nameSet = {}
		for token in input:gmatch("[^,]+") do
			local n = token:gsub("^%s+",""):gsub("%s+$","")
			if n ~= "" then nameSet[n] = true end
		end
		return scanPred(function(v)
			return v:IsA("BasePart") and nameSet[v.Name]
		end)
	end,
	function(v, _) return "[Part] " .. v.Name end
)

-- Part Find ESP — partial names, comma-separated  e.g. "Plat, Wall, Floor"
mkInputToggle("Part Find", "Part Find ESP — Partials (comma-sep)", "Plat, Wall, Fl, Ro ...",
	"partfind", Color3.fromRGB(255, 180, 80),
	function(input)
		local patterns = {}
		for token in input:gmatch("[^,]+") do
			local p = token:lower():gsub("^%s+",""):gsub("%s+$","")
			if p ~= "" then table.insert(patterns, p) end
		end
		return scanPred(function(v)
			if not v:IsA("BasePart") then return false end
			local lo = v.Name:lower()
			for _, pat in ipairs(patterns) do
				if lo:find(pat, 1, true) then return true end
			end
			return false
		end)
	end,
	function(v, _) return "[~] " .. v.Name end
)

-- Model ESP — exact model name
mkInputToggle("Model ESP", "Model ESP — Name", "e.g. Chest, Enemy, NPC...",
	"model", Color3.fromRGB(160, 100, 255),
	function(name)
		return scanPred(function(v) return v:IsA("Model") and v.Name == name end)
	end,
	function(v, name) return "[Model] " .. name end
)

-- Folder ESP — highlights folder's BasePart/Model children
mkInputToggle("Folder ESP", "Folder ESP — Name", "e.g. Items, Coins, Props...",
	"folder", Color3.fromRGB(255, 200, 100),
	function(name)
		local found = {}
		for _, v in ipairs(Workspace:GetDescendants()) do
			pcall(function()
				if v:IsA("Folder") and v.Name == name then
					for _, child in ipairs(v:GetChildren()) do
						if child:IsA("BasePart") or child:IsA("Model") then
							table.insert(found, child)
						end
					end
				end
			end)
		end
		return found
	end,
	function(v, name) return "[" .. name .. "] " .. v.Name end
)

-- Shape ESP — Block / Ball / Cylinder / Wedge / CornerWedge
mkInputToggle("Shape ESP", "Shape ESP", "Block / Ball / Cylinder / Wedge / CornerWedge",
	"shape", Color3.fromRGB(100, 255, 200),
	function(name)
		local map = {
			block       = Enum.PartType.Block,
			ball        = Enum.PartType.Ball,
			sphere      = Enum.PartType.Ball,
			cylinder    = Enum.PartType.Cylinder,
			wedge       = Enum.PartType.Wedge,
			cornerwedge = Enum.PartType.CornerWedge,
		}
		local target = map[name:lower()]
		if not target then return {} end
		return scanPred(function(v) return v:IsA("Part") and v.Shape == target end)
	end,
	function(v, name) return "[" .. name .. "] " .. v.Name end
)

-- Property ESP — format "PropertyName=Value"  e.g. "Material=Neon"
mkInputToggle("Property ESP", "Property ESP", "PropName=Value  e.g. Material=Neon",
	"prop", Color3.fromRGB(200, 100, 255),
	function(input)
		local propName, propVal = input:match("^%s*(.-)%s*=%s*(.+)%s*$")
		if not propName or propName == "" then return {} end
		return scanPred(function(v)
			local ok, val = pcall(function() return v[propName] end)
			if not ok then return false end
			return tostring(val):lower() == propVal:lower()
		end)
	end,
	function(v, input)
		local prop = input:match("^%s*(.-)%s*=") or "?"
		return "[" .. prop .. "] " .. v.Name
	end
)

-- === ESP LOCATOR ===
do
	local hasDrawing = false
	pcall(function()
		hasDrawing = Drawing ~= nil and type(Drawing.new) == "function"
	end)
	if hasDrawing then
		mkToggle("ESP Locator",
			function() enableLocator() end,
			function() disableLocator() end
		)
	else
		local b = newBtn("Locator N/A", Color3.fromRGB(55, 55, 75))
		b.Active = false
		b.TextColor3 = C.SUB
	end
end

-- === SPEED ===
do
	local speedVal  = 16
	local speedOn   = false
	local speedConn = nil

	local function applySpeed()
		if GetHum() then GetHum().WalkSpeed = speedVal end
	end

	local b = newBtn("Speed: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		local isActive = speedOn
		local title = isActive and "Change Speed" or "Set WalkSpeed"
		local ph    = isActive and ("Current: " .. speedVal .. "  |  Cancel = stop") or "e.g. 50, 100, 200..."
		showInput(title, ph, function(val)
			if not val then
				-- Cancel pressed
				if speedOn then
					speedOn = false
					b.BackgroundColor3 = C.RED
					b.Text = "Speed: OFF"
					if speedConn then speedConn:Disconnect() speedConn = nil end
					if GetHum() then GetHum().WalkSpeed = 16 end
				end
				return
			end
			local n = tonumber(val)
			if not n or n <= 0 then return end
			n = math.clamp(n, 1, 5000)
			speedVal = n
			speedOn  = true
			b.BackgroundColor3 = C.GRN
			b.Text = "Speed: " .. n
			applySpeed()
			if not speedConn then
				speedConn = lp.CharacterAdded:Connect(function()
					task.wait(0.5)
					if speedOn and GetHum() then GetHum().WalkSpeed = speedVal end
				end)
			end
		end)
	end)
end

-- === GOTO ===
do
	local b = newBtn("Goto", C.A2)
	b.MouseButton1Click:Connect(function()
		showInput("Goto — Player / NPC / X,Y,Z", "Name or x,y,z  e.g. 0,100,50", function(val)
			if not val or val:gsub("%s+", "") == "" then return end
			-- Try X,Y,Z coordinates
			local x, y, z = val:match("^%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*$")
			if x and y and z then
				local root = GetRoot()
				if root then root.CFrame = CFrame.new(tonumber(x), tonumber(y), tonumber(z)) end
				return
			end
			local lo = val:lower():gsub("^%s+", ""):gsub("%s+$", "")
			-- Try player name / display name
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp then
					local nameHit = p.Name:lower():find(lo, 1, true)
					local dispHit = false
					pcall(function()
						dispHit = p.DisplayName:lower():find(lo, 1, true) and true or false
					end)
					if nameHit or dispHit then
						local proot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
						if proot then
							local myRoot = GetRoot()
							if myRoot then myRoot.CFrame = proot.CFrame + Vector3.new(0, 3, 0) end
						end
						return
					end
				end
			end
			-- Try NPC / Model in workspace
			for _, v in ipairs(Workspace:GetDescendants()) do
				pcall(function()
					if v:IsA("Model") and v.Name:lower():find(lo, 1, true)
						and not Players:GetPlayerFromCharacter(v) then
						local nroot = v:FindFirstChild("HumanoidRootPart")
							or v:FindFirstChild("Torso")
							or v:FindFirstChildWhichIsA("BasePart")
						if nroot then
							local myRoot = GetRoot()
							if myRoot then myRoot.CFrame = nroot.CFrame + Vector3.new(0, 3, 0) end
						end
					end
				end)
			end
		end)
	end)
end

-- === UTILITY ACTIONS ===
do
	local b = newBtn("Rejoin", C.BLU)
	b.MouseButton1Click:Connect(function()
		pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end)
	end)
end

do
	local b = newBtn("Server Hop", C.BLU)
	b.MouseButton1Click:Connect(function()
		pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
	end)
end

do
	local b = newBtn("Reset Char", C.RED)
	b.MouseButton1Click:Connect(function()
		if GetHum() then GetHum().Health = 0 end
	end)
end

-- ================================================================
-- TELEPORT COMMANDS
-- ================================================================

-- Shared tween helper: lerps character CFrame to target over ~duration seconds
local function tweenGoto(targetCF, duration)
	local root = GetRoot()
	if not root then return end
	local hum = GetHum()
	if hum then hum.PlatformStand = true end
	local startCF  = root.CFrame
	local elapsed  = 0
	local tweenConn
	tweenConn = RunService.RenderStepped:Connect(function(dt)
		elapsed = elapsed + dt
		local t = math.min(elapsed / duration, 1)
		local e = t * t * (3 - 2 * t)  -- smoothstep
		pcall(function() root.CFrame = startCF:Lerp(targetCF, e) end)
		if t >= 1 then
			tweenConn:Disconnect()
			if GetHum() then GetHum().PlatformStand = false end
		end
	end)
end

-- Shared: resolve input string to a target CFrame (player / NPC / coords)
local function resolveTarget(val)
	local x, y, z = val:match("^%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*$")
	if x then return CFrame.new(tonumber(x), tonumber(y), tonumber(z)) end
	local lo = val:lower():gsub("^%s+",""):gsub("%s+$","")
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			local nameHit = p.Name:lower():find(lo, 1, true)
			local dispHit = false
			pcall(function()
				dispHit = p.DisplayName:lower():find(lo, 1, true) and true or false
			end)
			if nameHit or dispHit then
				local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if pr then return pr.CFrame + Vector3.new(0,3,0) end
			end
		end
	end
	for _, v in ipairs(Workspace:GetDescendants()) do
		local ok, res = pcall(function()
			if v:IsA("Model") and v.Name:lower():find(lo,1,true)
				and not Players:GetPlayerFromCharacter(v) then
				local nr = v:FindFirstChild("HumanoidRootPart")
					or v:FindFirstChild("Torso")
					or v:FindFirstChildWhichIsA("BasePart")
				if nr then return nr.CFrame + Vector3.new(0,3,0) end
			end
		end)
		if ok and res then return res end
	end
	return nil
end

-- Track last death position for Flashback
local lastDeathCF = nil
lp.CharacterRemoving:Connect(function(char)
	local dr = char:FindFirstChild("HumanoidRootPart")
	if dr then lastDeathCF = dr.CFrame end
end)

-- === TWEEN GOTO ===
do
	local b = newBtn("Tween Goto", C.A2)
	b.MouseButton1Click:Connect(function()
		showInput("Tween Goto", "Player / NPC / x,y,z", function(val)
			if not val or val:gsub("%s+","") == "" then return end
			local cf = resolveTarget(val)
			if cf then tweenGoto(cf, 1.5) end
		end)
	end)
end

-- === GLUE (loop teleport to player) ===
do
	local glueLoop   = nil
	local glueTarget = ""
	local b = newBtn("Glue: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		if glueLoop then
			glueLoop:Disconnect()
			glueLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Glue: OFF"
		else
			showInput("Glue — Player Name", "Target player name...", function(val)
				if not val or val:gsub("%s+","") == "" then return end
				glueTarget = val:lower():gsub("^%s+",""):gsub("%s+$","")
				b.BackgroundColor3 = C.GRN
				b.Text = "Glue: ON"
				glueLoop = RunService.Heartbeat:Connect(function()
					local root = GetRoot()
					if not root then return end
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= lp and p.Name:lower():find(glueTarget, 1, true) then
							local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							if pr then pcall(function() root.CFrame = pr.CFrame + Vector3.new(0,3,0) end) end
							return
						end
					end
				end)
			end)
		end
	end)
end

-- === TP UP ===
do
	local b = newBtn("TP Up", C.A2)
	b.MouseButton1Click:Connect(function()
		showInput("TP Up — Studs", "e.g. 10, 50, 100...", function(val)
			local n = tonumber(val)
			if not n then return end
			local root = GetRoot()
			if root then root.CFrame = root.CFrame + Vector3.new(0, n, 0) end
		end)
	end)
end

-- === TP DOWN ===
do
	local b = newBtn("TP Down", C.A2)
	b.MouseButton1Click:Connect(function()
		showInput("TP Down — Studs", "e.g. 10, 50, 100...", function(val)
			local n = tonumber(val)
			if not n then return end
			local root = GetRoot()
			if root then root.CFrame = root.CFrame - Vector3.new(0, n, 0) end
		end)
	end)
end

-- === GOTO CAMPOS ===
do
	local b = newBtn("CamPos TP", C.A2)
	b.MouseButton1Click:Connect(function()
		local root = GetRoot()
		if root then root.CFrame = Camera.CFrame end
	end)
end

-- === TWEEN TO CAMPOS ===
do
	local b = newBtn("CamPos Tween", C.A2)
	b.MouseButton1Click:Connect(function()
		tweenGoto(Camera.CFrame, 1.5)
	end)
end

-- === FLASHBACK (teleport to last death position) ===
do
	local b = newBtn("Flashback", C.ORG)
	b.MouseButton1Click:Connect(function()
		if not lastDeathCF then
			b.Text = "No death yet"
			task.delay(1.5, function() b.Text = "Flashback" end)
			return
		end
		local root = GetRoot()
		if root then root.CFrame = lastDeathCF end
	end)
end

-- === TP WALK (movement via teleporting instead of physics) ===
do
	local tpWalkOn    = false
	local tpWalkSpeed = 50
	local tpWalkLoop  = nil
	local tpWalkConn  = nil
	local b = newBtn("TP Walk: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		local isActive = tpWalkOn
		local title = isActive and "Change TP Walk Speed" or "TP Walk Speed"
		local ph    = isActive and ("Current: " .. tpWalkSpeed .. "  |  Cancel = stop") or "e.g. 50, 100..."
		showInput(title, ph, function(val)
			if not val then
				if tpWalkOn then
					tpWalkOn = false
					b.BackgroundColor3 = C.RED
					b.Text = "TP Walk: OFF"
					if tpWalkLoop then tpWalkLoop:Disconnect() tpWalkLoop = nil end
					if tpWalkConn then tpWalkConn:Disconnect() tpWalkConn = nil end
				end
				return
			end
			local n = tonumber(val)
			if not n or n <= 0 then return end
			n = math.clamp(n, 1, 3000)
			tpWalkSpeed = n
			tpWalkOn = true
			b.BackgroundColor3 = C.GRN
			b.Text = "TP Walk: " .. n
			if tpWalkLoop then tpWalkLoop:Disconnect() end
			tpWalkLoop = RunService.Heartbeat:Connect(function(dt)
				local hum  = GetHum()
				local root = GetRoot()
				if not hum or not root then return end
				local moveDir = hum.MoveDirection
				if moveDir.Magnitude > 0 then
					pcall(function()
						root.CFrame = root.CFrame + moveDir * tpWalkSpeed * dt
					end)
				end
			end)
			if not tpWalkConn then
				tpWalkConn = lp.CharacterAdded:Connect(function()
					task.wait(0.5)
					if tpWalkOn and tpWalkLoop then
						tpWalkLoop:Disconnect()
					end
					if tpWalkOn then
						tpWalkLoop = RunService.Heartbeat:Connect(function(dt)
							local hum  = GetHum()
							local root = GetRoot()
							if not hum or not root then return end
							local md = hum.MoveDirection
							if md.Magnitude > 0 then
								pcall(function() root.CFrame = root.CFrame + md * tpWalkSpeed * dt end)
							end
						end)
					end
				end)
			end
		end)
	end)
end

-- === ANTI-TELEPORT (block TeleportService via namecall hook) ===
do
	local antiTPOn   = false
	local antiTPOrigNC = nil  -- saved original __namecall for restoration
	local b = newBtn("Anti-TP: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		antiTPOn = not antiTPOn
		b.BackgroundColor3 = antiTPOn and C.GRN or C.RED
		b.Text = "Anti-TP: " .. (antiTPOn and "ON" or "OFF")
		if antiTPOn then
			-- Require ALL three executor APIs; bail silently if any is missing
			if type(getrawmetatable) ~= "function"
				or type(newcclosure) ~= "function"
				or type(getnamecallmethod) ~= "function" then
				return
			end
			pcall(function()
				local mt = getrawmetatable(game)
				if not mt then return end
				local origNC = rawget(mt, "__namecall")
				if type(origNC) ~= "function" then return end  -- never hook if nil
				antiTPOrigNC = origNC
				local blocked = {
					Teleport=true, TeleportAsync=true,
					TeleportToPlace=true, TeleportToPlaceInstance=true,
					TeleportToPrivateServer=true, TeleportPartyAsync=true,
				}
				mt.__namecall = newcclosure(function(self, ...)
					local ok, method = pcall(getnamecallmethod)
					if antiTPOn and ok and self == TeleportService and blocked[method] then
						return
					end
					return antiTPOrigNC(self, ...)
				end)
			end)
		else
			-- Restore original __namecall when disabled
			if antiTPOrigNC then
				pcall(function()
					local mt = getrawmetatable(game)
					if mt then mt.__namecall = antiTPOrigNC end
				end)
				antiTPOrigNC = nil
			end
		end
	end)
end

-- === CLIENT BRING (move player to you client-side, once) ===
do
	local b = newBtn("C.Bring", C.A1)
	b.MouseButton1Click:Connect(function()
		showInput("Client Bring — Player Name", "Target player name...", function(val)
			if not val or val:gsub("%s+","") == "" then return end
			local lo = val:lower():gsub("^%s+",""):gsub("%s+$","")
			local root = GetRoot()
			if not root then return end
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= lp and p.Name:lower():find(lo, 1, true) then
					local pchar = p.Character
					local proot = pchar and pchar:FindFirstChild("HumanoidRootPart")
					if proot then
						pcall(function() proot.CFrame = root.CFrame + Vector3.new(2, 0, 0) end)
					end
					return
				end
			end
		end)
	end)
end

-- === LOOP CLIENT BRING (continuously bring player client-side) ===
do
	local lcbLoop   = nil
	local lcbTarget = ""
	local b = newBtn("Loop C.Bring: OFF", C.RED)
	b.TextSize = 9
	b.MouseButton1Click:Connect(function()
		if lcbLoop then
			lcbLoop:Disconnect()
			lcbLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Loop C.Bring: OFF"
			b.TextSize = 9
		else
			showInput("Loop Client Bring — Player", "Target player name...", function(val)
				if not val or val:gsub("%s+","") == "" then return end
				lcbTarget = val:lower():gsub("^%s+",""):gsub("%s+$","")
				b.BackgroundColor3 = C.GRN
				b.Text = "Loop C.Bring: ON"
				b.TextSize = 9
				lcbLoop = RunService.Heartbeat:Connect(function()
					local root = GetRoot()
					if not root then return end
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= lp and p.Name:lower():find(lcbTarget, 1, true) then
							local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							if pr then pcall(function() pr.CFrame = root.CFrame + Vector3.new(2,0,0) end) end
							return
						end
					end
				end)
			end)
		end
	end)
end

-- === COPY TP SCRIPT (clipboard script to teleport to current position) ===
do
	local b = newBtn("Copy TP Script", C.BLU)
	b.MouseButton1Click:Connect(function()
		local root = GetRoot()
		if not root then return end
		local pos = root.Position
		local script = string.format(
			'game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(%g, %g, %g)',
			pos.X, pos.Y, pos.Z
		)
		pcall(setclipboard, script)
		b.Text = "Copied!"
		task.delay(1.5, function() b.Text = "Copy TP Script" end)
	end)
end

-- ================================================================
-- FLING / COMBAT
-- ================================================================

local Lighting = game:GetService("Lighting")

-- Shared: apply a BodyVelocity impulse to a character root (client-side)
local function doFling(targetRoot, force)
	force = force or 8e4
	pcall(function()
		local bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		local myRoot = GetRoot()
		local dir = myRoot
			and (targetRoot.Position - myRoot.Position).Unit
			or Vector3.new(0, 1, 0)
		if dir ~= dir then dir = Vector3.new(0, 1, 0) end  -- NaN guard
		bv.Velocity = (dir + Vector3.new(0, 0.5, 0)).Unit * force
		bv.Parent = targetRoot
		task.delay(0.15, function() pcall(function() bv:Destroy() end) end)
	end)
end

local function findPlayerRoot(nameStr)
	local lo = nameStr:lower():gsub("^%s+",""):gsub("%s+$","")
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp and p.Name:lower():find(lo, 1, true) then
			return p, p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		end
	end
	return nil, nil
end

-- === FLING (once) ===
do
	local b = newBtn("Fling", C.RED)
	b.MouseButton1Click:Connect(function()
		showInput("Fling — Player Name", "Target player name...", function(val)
			if not val or val:gsub("%s+","") == "" then return end
			local _, tRoot = findPlayerRoot(val)
			if not tRoot then return end
			local myRoot = GetRoot()
			if myRoot then pcall(function() myRoot.CFrame = tRoot.CFrame end) end
			doFling(tRoot)
		end)
	end)
end

-- === LOOP FLING (void) ===
do
	local loopFlingLoop = nil
	local b = newBtn("Loop Fling: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if loopFlingLoop then
			loopFlingLoop:Disconnect()
			loopFlingLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Loop Fling: OFF"
		else
			showInput("Loop Fling — Player", "Target player name...", function(val)
				if not val or val:gsub("%s+","") == "" then return end
				local tgt = val:lower():gsub("^%s+",""):gsub("%s+$","")
				b.BackgroundColor3 = C.GRN
				b.Text = "Loop Fling: ON"
				loopFlingLoop = RunService.Heartbeat:Connect(function()
					local myRoot = GetRoot()
					if not myRoot then return end
					for _, p in ipairs(Players:GetPlayers()) do
						if p ~= lp and p.Name:lower():find(tgt,1,true) then
							local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
							if tr then
								pcall(function() myRoot.CFrame = tr.CFrame end)
								doFling(tr, 1e5)
							end
							return
						end
					end
				end)
			end)
		end
	end)
end

-- === WALK FLING ===
do
	local wfOn   = false
	local wfOrig = 16
	local b = newBtn("Walk Fling: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		local isActive = wfOn
		showInput(isActive and "Change WF Speed" or "Walk Fling Speed",
			isActive and ("Current: " .. (GetHum() and GetHum().WalkSpeed or wfOrig) .. " | Cancel = stop") or "e.g. 300, 500...",
			function(val)
				if not val then
					if wfOn then
						wfOn = false
						b.BackgroundColor3 = C.RED
						b.Text = "Walk Fling: OFF"
						if GetHum() then GetHum().WalkSpeed = wfOrig end
					end
					return
				end
				local n = tonumber(val)
				if not n or n <= 0 then return end
				if not wfOn then wfOrig = GetHum() and GetHum().WalkSpeed or 16 end
				wfOn = true
				b.BackgroundColor3 = C.GRN
				b.Text = "Walk Fling: " .. n
				if GetHum() then GetHum().WalkSpeed = n end
			end)
	end)
end

-- === TOUCH FLING (fling nearby players) ===
do
	local tfLoop = nil
	local b = newBtn("Touch Fling: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if tfLoop then
			tfLoop:Disconnect() tfLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Touch Fling: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "Touch Fling: ON"
			tfLoop = RunService.Heartbeat:Connect(function()
				local myRoot = GetRoot()
				if not myRoot then return end
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= lp then
						local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
						if pr and (myRoot.Position - pr.Position).Magnitude < 6 then
							doFling(pr, 9e4)
						end
					end
				end
				for _, v in ipairs(Workspace:GetDescendants()) do
					pcall(function()
						if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid")
							and not Players:GetPlayerFromCharacter(v) then
							local nr = v:FindFirstChild("HumanoidRootPart")
							if nr and (myRoot.Position - nr.Position).Magnitude < 6 then
								doFling(nr, 9e4)
							end
						end
					end)
				end
			end)
		end
	end)
end

-- === CLICK FLING ===
do
	local cfConn = nil
	local b = newBtn("Click Fling: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if cfConn then
			cfConn:Disconnect() cfConn = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Click Fling: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "Click Fling: ON"
			cfConn = UserInputService.InputBegan:Connect(function(inp)
				if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
				local ray = Camera:ScreenPointToRay(inp.Position.X, inp.Position.Y)
				local res = Workspace:Raycast(ray.Origin, ray.Direction * 1200)
				if not res then return end
				local hit = res.Instance
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= lp and p.Character and p.Character:IsAncestorOf(hit) then
						local pr = p.Character:FindFirstChild("HumanoidRootPart")
						if pr then
							local myRoot = GetRoot()
							if myRoot then pcall(function() myRoot.CFrame = pr.CFrame end) end
							doFling(pr, 1e5)
						end
						return
					end
				end
			end)
		end
	end)
end

-- === INVIS FLING ===
do
	local b = newBtn("Invis Fling", C.RED)
	b.MouseButton1Click:Connect(function()
		showInput("Invis Fling — Player", "Target player name...", function(val)
			if not val or val:gsub("%s+","") == "" then return end
			local _, tRoot = findPlayerRoot(val)
			if not tRoot then return end
			local char = GetChar()
			if not char then return end
			-- Hide own character
			for _, v in ipairs(char:GetDescendants()) do
				pcall(function()
					if v:IsA("BasePart") then v.LocalTransparencyModifier = 1 end
				end)
			end
			local myRoot = GetRoot()
			if myRoot then pcall(function() myRoot.CFrame = tRoot.CFrame end) end
			doFling(tRoot, 1.2e5)
			-- Restore after short delay
			task.delay(1, function()
				if GetChar() then
					for _, v in ipairs(GetChar():GetDescendants()) do
						pcall(function()
							if v:IsA("BasePart") then v.LocalTransparencyModifier = 0 end
						end)
					end
				end
			end)
		end)
	end)
end

-- === FLY FLING (fly + fling on contact) ===
do
	local ffOn = false
	local ffBodyVel, ffBodyGyro, ffFlyLoop, ffFlingLoop
	local FF_SPEED = 80
	local b = newBtn("Fly Fling: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		ffOn = not ffOn
		b.BackgroundColor3 = ffOn and C.GRN or C.RED
		b.Text = "Fly Fling: " .. (ffOn and "ON" or "OFF")
		if ffOn then
			local root = GetRoot()
			if root then
				pcall(function() if ffBodyVel then ffBodyVel:Destroy() end end)
				pcall(function() if ffBodyGyro then ffBodyGyro:Destroy() end end)
				pcall(function()
					ffBodyVel = Instance.new("BodyVelocity")
					ffBodyVel.MaxForce = Vector3.new(1e9,1e9,1e9)
					ffBodyVel.Velocity = Vector3.new(0,0,0)
					ffBodyVel.Parent = root
				end)
				pcall(function()
					ffBodyGyro = Instance.new("BodyGyro")
					ffBodyGyro.MaxTorque = Vector3.new(1e9,1e9,1e9)
					ffBodyGyro.P = 9e4
					ffBodyGyro.CFrame = root.CFrame
					ffBodyGyro.Parent = root
				end)
				if GetHum() then GetHum().PlatformStand = true end
			end
			ffFlyLoop = RunService.RenderStepped:Connect(function()
				local r = GetRoot()
				local h = GetHum()
				if not r or not h or not ffBodyVel or not ffBodyGyro then return end
				pcall(function()
					ffBodyGyro.CFrame = Camera.CFrame
					local md = h.MoveDirection
					if md.Magnitude > 0 then
						local cam = Camera.CFrame
						local rel = cam:VectorToObjectSpace(md)
						local dir = cam.LookVector * (-rel.Z) + cam.RightVector * rel.X
						ffBodyVel.Velocity = dir.Unit * FF_SPEED
					else ffBodyVel.Velocity = Vector3.new(0,0,0) end
				end)
			end)
			ffFlingLoop = RunService.Heartbeat:Connect(function()
				local myRoot = GetRoot()
				if not myRoot then return end
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= lp then
						local pr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
						if pr and (myRoot.Position - pr.Position).Magnitude < 7 then
							doFling(pr, 1.2e5)
						end
					end
				end
			end)
		else
			if ffFlyLoop  then ffFlyLoop:Disconnect()  ffFlyLoop  = nil end
			if ffFlingLoop then ffFlingLoop:Disconnect() ffFlingLoop = nil end
			if ffBodyVel  then ffBodyVel:Destroy()     ffBodyVel  = nil end
			if ffBodyGyro then ffBodyGyro:Destroy()    ffBodyGyro = nil end
			if GetHum()   then GetHum().PlatformStand = false end
		end
	end)
end

-- === ANTI-FLING (make other players non-collidable with you) ===
do
	local afLoop = nil
	local b = newBtn("Anti-Fling: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if afLoop then
			afLoop:Disconnect() afLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Anti-Fling: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "Anti-Fling: ON"
			afLoop = RunService.Heartbeat:Connect(function()
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= lp and p.Character then
						for _, v in ipairs(p.Character:GetDescendants()) do
							pcall(function()
								if v:IsA("BasePart") then v.CanCollide = false end
							end)
						end
					end
				end
			end)
		end
	end)
end

-- === ANTI-FLING PARTS (no-collide nearby fast unanchored parts) ===
do
	local afpLoop = nil
	local b = newBtn("AF Parts: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if afpLoop then
			afpLoop:Disconnect() afpLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "AF Parts: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "AF Parts: ON"
			afpLoop = RunService.Heartbeat:Connect(function()
				local myRoot = GetRoot()
				if not myRoot then return end
				for _, v in ipairs(Workspace:GetDescendants()) do
					pcall(function()
						if v:IsA("BasePart") and not v.Anchored then
							local vel = v.AssemblyLinearVelocity
							if vel and vel.Magnitude > 40 and
								(myRoot.Position - v.Position).Magnitude < 30 then
								v.CanCollide = false
							end
						end
					end)
				end
			end)
		end
	end)
end

-- ================================================================
-- GOD / SURVIVAL
-- ================================================================

-- === GOD MODE (health loop) ===
do
	local godLoop = nil
	local b = newBtn("God Mode: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if godLoop then
			godLoop:Disconnect() godLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "God Mode: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "God Mode: ON"
			godLoop = RunService.Heartbeat:Connect(function()
				local hum = GetHum()
				if hum then
					hum.Health = hum.MaxHealth
					pcall(function() hum.MaxHealth = math.huge end)
				end
			end)
		end
	end)
end

-- === ANTI-TOUCH (disable killbricks) ===
do
	local atParts = {}
	local b = newBtn("Anti-Touch: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if #atParts > 0 then
			for _, d in ipairs(atParts) do
				pcall(function() d.part.CanTouch = d.orig end)
			end
			atParts = {}
			b.BackgroundColor3 = C.RED
			b.Text = "Anti-Touch: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "Anti-Touch: ON"
			for _, v in ipairs(Workspace:GetDescendants()) do
				pcall(function()
					if v:IsA("BasePart") and v:FindFirstChildOfClass("TouchTransmitter") then
						table.insert(atParts, {part=v, orig=v.CanTouch})
						v.CanTouch = false
					end
				end)
			end
		end
	end)
end

-- === LOOP ANTI-TOUCH (live tracking) ===
do
	local latLoop = nil
	local b = newBtn("Loop Anti-Touch", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if latLoop then
			latLoop:Disconnect() latLoop = nil
			b.BackgroundColor3 = C.RED
			b.Text = "Loop Anti-Touch"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "Loop A-Touch: ON"
			latLoop = RunService.Heartbeat:Connect(function()
				for _, v in ipairs(Workspace:GetDescendants()) do
					pcall(function()
						if v:IsA("BasePart") and v:FindFirstChildOfClass("TouchTransmitter")
							and v.CanTouch then
							v.CanTouch = false
						end
					end)
				end
			end)
		end
	end)
end

-- === NO RESET ===
do
	local noResetOn = false
	local b = newBtn("No Reset: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		noResetOn = not noResetOn
		b.BackgroundColor3 = noResetOn and C.GRN or C.RED
		b.Text = "No Reset: " .. (noResetOn and "ON" or "OFF")
		pcall(function()
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCore("ResetButtonCallback", noResetOn and function() end or true)
		end)
	end)
end

-- ================================================================
-- INVISIBILITY
-- ================================================================

-- === INVISIBLE ===
do
	local invisOn   = false
	local invisConn = nil
	local function applyInvis(on)
		local char = GetChar()
		if not char then return end
		for _, v in ipairs(char:GetDescendants()) do
			pcall(function()
				if v:IsA("BasePart") then
					v.LocalTransparencyModifier = on and 1 or 0
				end
			end)
		end
	end
	local b = newBtn("Invisible: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		invisOn = not invisOn
		b.BackgroundColor3 = invisOn and C.GRN or C.RED
		b.Text = "Invisible: " .. (invisOn and "ON" or "OFF")
		applyInvis(invisOn)
		if invisOn then
			if not invisConn then
				invisConn = lp.CharacterAdded:Connect(function()
					task.wait(0.5)
					if invisOn then applyInvis(true) end
				end)
			end
		else
			if invisConn then invisConn:Disconnect() invisConn = nil end
		end
	end)
end

-- === INVIS PARTS (highlight invisible parts so you can see them) ===
do
	local ipHLs = {}
	local b = newBtn("Invis Parts: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		if next(ipHLs) then
			for _, hl in pairs(ipHLs) do pcall(function() hl:Destroy() end) end
			ipHLs = {}
			b.BackgroundColor3 = C.RED
			b.Text = "Invis Parts: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "Invis Parts: ON"
			local char = GetChar()
			for _, v in ipairs(Workspace:GetDescendants()) do
				pcall(function()
					if v:IsA("BasePart") and v.Transparency >= 0.99
						and (not char or not char:IsAncestorOf(v)) then
						local hl = Instance.new("Highlight")
						hl.FillColor = Color3.fromRGB(0, 200, 255)
						hl.OutlineColor = Color3.fromRGB(0, 200, 255)
						hl.FillTransparency = 0.45
						hl.OutlineTransparency = 0
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Adornee = v
						hl.Parent = workspace
						ipHLs[v] = hl
					end
				end)
			end
		end
	end)
end

-- === DELETE INVIS PARTS ===
do
	local b = newBtn("Del Invis Parts", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		local char = GetChar()
		local count = 0
		for _, v in ipairs(Workspace:GetDescendants()) do
			pcall(function()
				if v:IsA("BasePart") and v.Transparency >= 0.99
					and (not char or not char:IsAncestorOf(v)) then
					v:Destroy()
					count = count + 1
				end
			end)
		end
		b.Text = "Deleted " .. count
		task.delay(2, function() b.Text = "Del Invis Parts" end)
	end)
end

-- ================================================================
-- FREECAM
-- ================================================================

do
	local fcOn       = false
	local fcSpeed    = 50
	local fcLoop     = nil
	local fcSavedType, fcSavedSubject

	local function enableFC(speed)
		fcSpeed = speed or 50
		fcSavedType    = Camera.CameraType
		fcSavedSubject = Camera.CameraSubject
		Camera.CameraType = Enum.CameraType.Scriptable
		local moveMap = {
			[Enum.KeyCode.W]     = Vector3.new( 0, 0,-1),
			[Enum.KeyCode.S]     = Vector3.new( 0, 0, 1),
			[Enum.KeyCode.A]     = Vector3.new(-1, 0, 0),
			[Enum.KeyCode.D]     = Vector3.new( 1, 0, 0),
			[Enum.KeyCode.E]     = Vector3.new( 0, 1, 0),
			[Enum.KeyCode.Q]     = Vector3.new( 0,-1, 0),
			[Enum.KeyCode.Space] = Vector3.new( 0, 1, 0),
		}
		fcLoop = RunService.RenderStepped:Connect(function(dt)
			local dir = Vector3.new(0, 0, 0)
			for key, vec in pairs(moveMap) do
				if UserInputService:IsKeyDown(key) then dir = dir + vec end
			end
			if dir.Magnitude > 0 then
				Camera.CFrame = Camera.CFrame
					+ Camera.CFrame:VectorToWorldSpace(dir.Unit * fcSpeed * dt)
			end
		end)
	end

	local function disableFC()
		if fcLoop then fcLoop:Disconnect() fcLoop = nil end
		Camera.CameraType = fcSavedType or Enum.CameraType.Custom
		pcall(function() Camera.CameraSubject = fcSavedSubject end)
	end

	local b = newBtn("Freecam: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		local isActive = fcOn
		local title = isActive and "Change FC Speed" or "Freecam Speed"
		local ph    = isActive and ("Current: " .. fcSpeed .. " | Cancel = stop") or "e.g. 50, 100, 200..."
		showInput(title, ph, function(val)
			if not val then
				if fcOn then
					fcOn = false
					b.BackgroundColor3 = C.RED
					b.Text = "Freecam: OFF"
					disableFC()
				end
				return
			end
			local n = tonumber(val)
			if not n or n <= 0 then return end
			n = math.clamp(n, 1, 2000)
			fcSpeed = n
			fcOn    = true
			b.BackgroundColor3 = C.GRN
			b.Text = "Freecam: " .. n
			if fcLoop then fcLoop:Disconnect() fcLoop = nil end
			enableFC(n)
		end)
	end)
end

-- ================================================================
-- VISUAL
-- ================================================================

-- === XRAY (see through walls) ===
do
	local xrParts = {}
	local b = newBtn("XRay: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		if #xrParts > 0 then
			for _, d in ipairs(xrParts) do
				pcall(function() d.part.LocalTransparencyModifier = d.orig end)
			end
			xrParts = {}
			b.BackgroundColor3 = C.RED
			b.Text = "XRay: OFF"
		else
			b.BackgroundColor3 = C.GRN
			b.Text = "XRay: ON"
			local char = GetChar()
			for _, v in ipairs(Workspace:GetDescendants()) do
				pcall(function()
					if v:IsA("BasePart") and (not char or not char:IsAncestorOf(v)) then
						table.insert(xrParts, {part=v, orig=v.LocalTransparencyModifier})
						v.LocalTransparencyModifier = math.max(v.LocalTransparencyModifier, 0.7)
					end
				end)
			end
		end
	end)
end

-- === FULLBRIGHT ===
do
	local fbOn  = false
	local fbOrig = {}
	local b = newBtn("Fullbright: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		fbOn = not fbOn
		b.BackgroundColor3 = fbOn and C.GRN or C.RED
		b.Text = "Fullbright: " .. (fbOn and "ON" or "OFF")
		if fbOn then
			fbOrig = {
				Brightness = Lighting.Brightness,
				ClockTime  = Lighting.ClockTime,
				FogEnd     = Lighting.FogEnd,
				FogStart   = Lighting.FogStart,
				GlobalShadows = Lighting.GlobalShadows,
				Ambient       = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
			}
			Lighting.Brightness = 2
			Lighting.ClockTime  = 14
			Lighting.FogEnd     = 1e8
			Lighting.GlobalShadows = false
			Lighting.Ambient       = Color3.fromRGB(178, 178, 178)
			Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
			for _, v in ipairs(Lighting:GetChildren()) do
				pcall(function()
					if v:IsA("Atmosphere") then
						fbOrig._atmoD = v.Density
						fbOrig._atmoH = v.Haze
						fbOrig._atmoG = v.Glare
						v.Density = 0
						v.Haze    = 0
						v.Glare   = 0
					end
				end)
			end
		else
			Lighting.Brightness    = fbOrig.Brightness    or 1
			Lighting.ClockTime     = fbOrig.ClockTime     or 14
			Lighting.FogEnd        = fbOrig.FogEnd        or 1e4
			Lighting.FogStart      = fbOrig.FogStart      or 0
			Lighting.GlobalShadows = fbOrig.GlobalShadows ~= nil and fbOrig.GlobalShadows or true
			Lighting.Ambient       = fbOrig.Ambient       or Color3.fromRGB(70, 70, 70)
			Lighting.OutdoorAmbient = fbOrig.OutdoorAmbient or Color3.fromRGB(70, 70, 70)
			for _, v in ipairs(Lighting:GetChildren()) do
				pcall(function()
					if v:IsA("Atmosphere") and fbOrig._atmoD then
						v.Density = fbOrig._atmoD
						v.Haze    = fbOrig._atmoH or 0
						v.Glare   = fbOrig._atmoG or 0
					end
				end)
			end
		end
	end)
end

-- === NO FOG ===
do
	local nfOn  = false
	local nfOrig = {}
	local b = newBtn("No Fog: OFF", C.RED)
	b.MouseButton1Click:Connect(function()
		nfOn = not nfOn
		b.BackgroundColor3 = nfOn and C.GRN or C.RED
		b.Text = "No Fog: " .. (nfOn and "ON" or "OFF")
		if nfOn then
			nfOrig = {
				FogEnd   = Lighting.FogEnd,
				FogStart = Lighting.FogStart,
			}
			Lighting.FogEnd   = 1e8
			Lighting.FogStart = 1e7
			for _, v in ipairs(Lighting:GetChildren()) do
				pcall(function()
					if v:IsA("Atmosphere") then
						nfOrig._atmoD = v.Density
						nfOrig._atmoH = v.Haze
						v.Density = 0
						v.Haze    = 0
					end
				end)
			end
		else
			Lighting.FogEnd   = nfOrig.FogEnd   or 1e4
			Lighting.FogStart = nfOrig.FogStart  or 0
			for _, v in ipairs(Lighting:GetChildren()) do
				pcall(function()
					if v:IsA("Atmosphere") and nfOrig._atmoD then
						v.Density = nfOrig._atmoD
						v.Haze    = nfOrig._atmoH or 0
					end
				end)
			end
		end
	end)
end

-- === BRIGHTNESS (input) ===
do
	local brightOn   = false
	local brightOrig = nil
	local b = newBtn("Brightness: OFF", C.RED)
	b.TextSize = 10
	b.MouseButton1Click:Connect(function()
		local isActive = brightOn
		showInput(isActive and "Change Brightness" or "Set Brightness",
			isActive and ("Current: " .. Lighting.Brightness .. " | Cancel = restore") or "e.g. 1, 2, 5, 10...",
			function(val)
				if not val then
					if brightOn then
						brightOn = false
						b.BackgroundColor3 = C.RED
						b.Text = "Brightness: OFF"
						if brightOrig then Lighting.Brightness = brightOrig end
					end
					return
				end
				local n = tonumber(val)
				if not n or n < 0 then return end
				if not brightOn then brightOrig = Lighting.Brightness end
				brightOn = true
				b.BackgroundColor3 = C.GRN
				b.Text = "Bright: " .. n
				Lighting.Brightness = n
			end)
	end)
end

-- ================================================================
-- AUDIO LOGIC
-- ================================================================
local allSounds = {}
local soundMeta = {}
local activeFilter = "All Audios"
local searchQuery = ""
local selectedSound = nil
local selectedRow = nil
local isLooping = false
local loopInst = nil
local singleInst = nil
local isPlayingSingle = false
local playStateDebounce = false
local minimized = false
local scanning = false
local rebuildId = 0
local searchTimer = nil

local function cacheMeta(snd)
	local id = extractId(snd)
	local dur = snd.TimeLength or 0
	local fp = getFullPath(snd)
	local cat
	if dur >= 25 then
		cat = "Music"
	elseif dur > 0 then
		cat = "SFX"
	else
		local p = fp:lower()
		local n = snd.Name:lower()
		if p:find("music") or p:find("ambient") or p:find("song") or p:find("ost")
		or n:find("music") or n:find("theme") or n:find("song") or n:find("bgm") or n:find("ost")
		or snd.Looped == true then
			cat = "Music"
		else
			cat = "SFX"
		end
	end
	local after = fp:match("^[Ww]orkspace%.(.+)$")
	soundMeta[snd] = {
		id = id, dur = dur, fp = fp, cat = cat,
		durStr = fmtDuration(dur),
		lastName = fp:match("([^%.]+)$") or "?",
		wsStr = after and ("workspace." .. after) or ("workspace." .. fp),
	}
end

local function clearSel()
	selectedSound = nil
	rsName.Text = "—"
	rsId.Text = "—"
	rsDur.Text = "—"
	rsCat.Text = "—"
	rsPath.Text = "—"
	wsLbl.Text = "workspace.—"
end

local function setSel(snd)
	selectedSound = snd
	if not snd then clearSel() return end
	local m = soundMeta[snd]
	if m then
		rsName.Text = snd.Name
		rsId.Text = m.id ~= "" and m.id or "unknown"
		rsDur.Text = m.durStr
		rsCat.Text = m.cat
		rsPath.Text = "Path: " .. m.fp
		wsLbl.Text = m.wsStr
	else
		local id = extractId(snd)
		local dur = snd.TimeLength or 0
		local fp = getFullPath(snd)
		rsName.Text = snd.Name
		rsId.Text = id ~= "" and id or "unknown"
		rsDur.Text = fmtDuration(dur)
		rsCat.Text = getCategory(snd)
		rsPath.Text = "Path: " .. fp
		wsLbl.Text = wsPath(snd)
	end
end

local function rowOk(snd)
	local m = soundMeta[snd]
	local cat = m and m.cat or getCategory(snd)
	if activeFilter ~= "All Audios" and activeFilter ~= cat then return false end
	if searchQuery ~= "" then
		local q = searchQuery:lower()
		local id = m and m.id or extractId(snd)
		if not snd.Name:lower():find(q, 1, true) and not id:find(q, 1, true) then
			return false
		end
	end
	return true
end

local function rebuild()
	rebuildId = rebuildId + 1
	local myId = rebuildId
	for _, c in ipairs(sf:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	selectedRow = nil
	local filtered = {}
	for i, snd in ipairs(allSounds) do
		if rowOk(snd) then table.insert(filtered, {idx = i, snd = snd}) end
	end
	countL.Text = #filtered .. " found"
	for n, entry in ipairs(filtered) do
		if rebuildId ~= myId then return end
		local snd = entry.snd
		local m = soundMeta[snd] or {}
		local id = m.id or extractId(snd)
		local durStr = m.durStr or fmtDuration(snd.TimeLength or 0)
		local lastName = m.lastName or (getFullPath(snd):match("([^%.]+)$") or "?")
		local row = Instance.new("TextButton", sf)
		row.Size = UDim2.new(1, 0, 0, 36)
		row.BackgroundColor3 = C.BG
		row.BorderSizePixel = 0
		row.Text = ""
		row.LayoutOrder = entry.idx
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
		local nL = Instance.new("TextLabel", row)
		nL.Size = UDim2.new(0.37, -10, 1, 0)
		nL.Position = UDim2.new(0, 8, 0, 0)
		nL.BackgroundTransparency = 1
		nL.Text = snd.Name
		nL.TextColor3 = C.TXT
		nL.TextSize = 12
		nL.Font = Enum.Font.Gotham
		nL.TextXAlignment = Enum.TextXAlignment.Left
		nL.TextTruncate = Enum.TextTruncate.AtEnd
		local iL = Instance.new("TextLabel", row)
		iL.Size = UDim2.new(0.31, -4, 1, 0)
		iL.Position = UDim2.new(0.37, 2, 0, 0)
		iL.BackgroundTransparency = 1
		iL.Text = id ~= "" and id or "—"
		iL.TextColor3 = C.A3
		iL.TextSize = 11
		iL.Font = Enum.Font.Code
		iL.TextXAlignment = Enum.TextXAlignment.Left
		iL.TextTruncate = Enum.TextTruncate.AtEnd
		local dL = Instance.new("TextLabel", row)
		dL.Size = UDim2.new(0.16, -4, 1, 0)
		dL.Position = UDim2.new(0.68, 2, 0, 0)
		dL.BackgroundTransparency = 1
		dL.Text = durStr
		dL.TextColor3 = C.SUB
		dL.TextSize = 11
		dL.Font = Enum.Font.Gotham
		local pL = Instance.new("TextLabel", row)
		pL.Size = UDim2.new(0.16, -6, 1, 0)
		pL.Position = UDim2.new(0.84, 2, 0, 0)
		pL.BackgroundTransparency = 1
		pL.Text = lastName
		pL.TextColor3 = Color3.fromRGB(115, 105, 155)
		pL.TextSize = 9
		pL.Font = Enum.Font.Code
		pL.TextTruncate = Enum.TextTruncate.AtEnd
		row.MouseButton1Click:Connect(function()
			if selectedRow then selectedRow.BackgroundColor3 = C.BG end
			row.BackgroundColor3 = C.SEL
			selectedRow = row
			setSel(snd)
		end)
		row.MouseEnter:Connect(function()
			if row ~= selectedRow then row.BackgroundColor3 = C.HOV end
		end)
		row.MouseLeave:Connect(function()
			if row ~= selectedRow then row.BackgroundColor3 = C.BG end
		end)
		if n % 25 == 0 then
			sf.CanvasSize = UDim2.new(0, 0, 0, sfl.AbsoluteContentSize.Y)
			task.wait()
		end
	end
	if rebuildId == myId then
		sf.CanvasSize = UDim2.new(0, 0, 0, sfl.AbsoluteContentSize.Y)
	end
end

local IGNORE_SOUNDS = {
	["Climbing"] = true, ["Died"] = true, ["FreeFalling"] = true,
	["GettingUp"] = true, ["Jumping"] = true, ["Landing"] = true,
	["Running"] = true, ["Splash"] = true, ["Swimming"] = true,
	["Walking"] = true
}

local function doScan()
	if scanning then return end
	scanning = true
	refreshBtn.Text = "Scanning..."
	refreshBtn.BackgroundColor3 = C.ORG
	allSounds = {}
	soundMeta = {}
	clearSel()
	statusL.Text = "Scanning SoundService & Workspace..."
	local scanN = 0
	local function recurse(parent)
		local ok, ch = pcall(parent.GetChildren, parent)
		if not ok then return end
		for _, v in ipairs(ch) do
			pcall(function()
				if v:IsA("Sound") and not IGNORE_SOUNDS[v.Name] then
					table.insert(allSounds, v)
					cacheMeta(v)
					scanN = scanN + 1
					if scanN % 3 == 0 then
						local m = soundMeta[v]
						statusL.Text = "Found Audio  (ID: " .. (m and m.id or "") .. ")  (Dur: " .. (m and m.durStr or "0:00") .. ")"
						task.wait()
					end
				end
			end)
			pcall(function()
				if #v:GetChildren() > 0 then recurse(v) end
			end)
		end
	end
	recurse(game:GetService("SoundService"))
	recurse(workspace)
	if #allSounds > 0 then
		local last = allSounds[#allSounds]
		local m = soundMeta[last]
		statusL.Text = "Found Audio  (ID: " .. (m and m.id or "") .. ")  (Dur: " .. (m and m.durStr or "0:00") .. ")"
	end
	local unloaded = {}
	for _, s in ipairs(allSounds) do
		if not s.IsLoaded then table.insert(unloaded, s) end
	end
	if #unloaded > 0 then
		statusL.Text = "Loading metadata  (" .. #unloaded .. " pending)..."
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(unloaded)
		end)
		for _, s in ipairs(allSounds) do cacheMeta(s) end
	end
	task.spawn(rebuild)
	task.wait(2.5)
	statusL.Text = ""
	refreshBtn.Text = "Refresh List"
	refreshBtn.BackgroundColor3 = C.A2
	scanning = false
end

local function setFilter(f)
	activeFilter = f
	fAll.BackgroundColor3   = f == "All Audios" and C.A1 or C.PANEL
	fMusic.BackgroundColor3 = f == "Music"      and C.A1 or C.PANEL
	fSFX.BackgroundColor3   = f == "SFX"        and C.A1 or C.PANEL
	task.spawn(rebuild)
end

fAll.MouseButton1Click:Connect(function() setFilter("All Audios") end)
fMusic.MouseButton1Click:Connect(function() setFilter("Music") end)
fSFX.MouseButton1Click:Connect(function() setFilter("SFX") end)
refreshBtn.MouseButton1Click:Connect(function() task.spawn(doScan) end)

sbBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = sbBox.Text
	if searchTimer then task.cancel(searchTimer) end
	searchTimer = task.delay(0.3, function() task.spawn(rebuild) end)
end)

local function stopSingleSound()
	if singleInst then
		singleInst:Stop()
		singleInst:Destroy()
		singleInst = nil
	end
	isPlayingSingle = false
end

btnPlay.MouseButton1Click:Connect(function()
	if playStateDebounce then return end
	if isPlayingSingle then
		playStateDebounce = true
		stopSingleSound()
		btnPlay.Text = "Canceled!"
		btnPlay.BackgroundColor3 = C.RED
		task.wait(1.2)
		btnPlay.Text = "Play Audio"
		btnPlay.BackgroundColor3 = C.GRN
		playStateDebounce = false
		return
	end
	if not selectedSound then return end
	if isLooping and loopInst then
		isLooping = false
		loopInst:Stop()
		loopInst:Destroy()
		loopInst = nil
		btnLoop.Text = "Loop Play Audio"
		btnLoop.BackgroundColor3 = C.ORG
	end
	local m = soundMeta[selectedSound]
	local id = m and m.id or extractId(selectedSound)
	if id == "" then return end
	isPlayingSingle = true
	btnPlay.Text = "Cancel Playing Audio"
	btnPlay.BackgroundColor3 = C.RED
	singleInst = Instance.new("Sound")
	singleInst.SoundId = "rbxassetid://" .. id
	singleInst.Volume = 0.5
	singleInst.Parent = workspace
	singleInst:Play()
	local duration = math.max((m and m.dur or selectedSound.TimeLength or 0), 1)
	task.spawn(function()
		local myInst = singleInst
		task.wait(duration)
		if isPlayingSingle and singleInst == myInst then
			stopSingleSound()
			btnPlay.Text = "Play Audio"
			btnPlay.BackgroundColor3 = C.GRN
		end
	end)
end)

btnLoop.MouseButton1Click:Connect(function()
	if not selectedSound then return end
	if isPlayingSingle then
		stopSingleSound()
		btnPlay.Text = "Play Audio"
		btnPlay.BackgroundColor3 = C.GRN
	end
	if isLooping then
		isLooping = false
		if loopInst then loopInst:Stop() loopInst:Destroy() loopInst = nil end
		btnLoop.Text = "Loop Play Audio"
		btnLoop.BackgroundColor3 = C.ORG
		return
	end
	local m = soundMeta[selectedSound]
	local id = m and m.id or extractId(selectedSound)
	if id == "" then return end
	isLooping = true
	btnLoop.Text = "Stop Loop"
	btnLoop.BackgroundColor3 = C.RED
	loopInst = Instance.new("Sound")
	loopInst.SoundId = "rbxassetid://" .. id
	loopInst.Volume = 0.5
	loopInst.Looped = true
	loopInst.Parent = workspace
	loopInst:Play()
end)

local copying = false
btnCopy.MouseButton1Click:Connect(function()
	if not selectedSound or copying then return end
	local m = soundMeta[selectedSound]
	local id = m and m.id or extractId(selectedSound)
	if id == "" then return end
	copying = true
	pcall(setclipboard, id)
	btnCopy.Text = "Copied!"
	task.wait(1.2)
	btnCopy.Text = "Copy Asset Id"
	copying = false
end)

-- ================================================================
-- IMAGE LOGIC
-- ================================================================
local allImages = {}
local imageMeta = {}
local activeImgFilter = "All Images"
local imgSearchQuery = ""
local selectedImage = nil
local selectedImgRow = nil
local imgScanning = false
local imgRebuildId = 0
local imgSearchTimer = nil
local seenImgIds = {}

local function cacheImgMeta(inst)
	local url, instType = "", ""
	if inst:IsA("ImageLabel") then
		url = tostring(inst.Image or "")
		instType = "ImageLabel"
	elseif inst:IsA("ImageButton") then
		url = tostring(inst.Image or "")
		instType = "ImgButton"
	elseif inst:IsA("Decal") then
		url = tostring(inst.Texture or "")
		instType = "Decal"
	elseif inst:IsA("Texture") then
		url = tostring(inst.Texture or "")
		instType = "Texture"
	elseif inst:IsA("SpecialMesh") then
		url = tostring(inst.TextureId or "")
		instType = "Mesh"
	elseif inst:IsA("MeshPart") then
		url = tostring(inst.TextureID or "")
		instType = "MeshPart"
	else
		return false
	end
	if url:find("rbxasset://") then return false end
	local id = extractImgId(url)
	if id == "" then return false end
	local fp = getFullPath(inst)
	imageMeta[inst] = {
		id = id, fp = fp, instType = instType,
		lastName = fp:match("([^%.]+)$") or "?",
	}
	return true
end

local function clearImgSel()
	selectedImage = nil
	iPreview.Image = ""
	irsName.Text = "—"
	irsId.Text = "—"
	irsType.Text = "—"
	irsPath.Text = "—"
end

local function setImgSel(inst)
	selectedImage = inst
	if not inst then clearImgSel() return end
	local m = imageMeta[inst]
	if not m then return end
	irsName.Text = inst.Name
	irsId.Text = m.id
	irsType.Text = m.instType
	irsPath.Text = m.fp
	iPreview.Image = "rbxassetid://" .. m.id
end

local function imgRowOk(inst)
	local m = imageMeta[inst]
	if not m then return false end
	if activeImgFilter ~= "All Images" then
		if activeImgFilter == "Decal"      and not inst:IsA("Decal") then return false end
		if activeImgFilter == "Texture"    and not inst:IsA("Texture") then return false end
		if activeImgFilter == "ImageLabel" and not (inst:IsA("ImageLabel") or inst:IsA("ImageButton")) then return false end
	end
	if imgSearchQuery ~= "" then
		local q = imgSearchQuery:lower()
		if not inst.Name:lower():find(q, 1, true) and not m.id:find(q, 1, true) then
			return false
		end
	end
	return true
end

local function imgRebuild()
	imgRebuildId = imgRebuildId + 1
	local myId = imgRebuildId
	for _, c in ipairs(isf:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	selectedImgRow = nil
	local filtered = {}
	for i, inst in ipairs(allImages) do
		if imgRowOk(inst) then table.insert(filtered, {idx = i, inst = inst}) end
	end
	countL.Text = #filtered .. " found"
	for n, entry in ipairs(filtered) do
		if imgRebuildId ~= myId then return end
		local inst = entry.inst
		local m = imageMeta[inst]
		local row = Instance.new("TextButton", isf)
		row.Size = UDim2.new(1, 0, 0, 38)
		row.BackgroundColor3 = C.BG
		row.BorderSizePixel = 0
		row.Text = ""
		row.LayoutOrder = entry.idx
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
		local thumb = Instance.new("ImageLabel", row)
		thumb.Size = UDim2.new(0, 30, 0, 30)
		thumb.Position = UDim2.new(0, 4, 0.5, -15)
		thumb.BackgroundColor3 = C.CODE
		thumb.BorderSizePixel = 0
		thumb.ScaleType = Enum.ScaleType.Fit
		thumb.Image = "rbxassetid://" .. m.id
		Instance.new("UICorner", thumb).CornerRadius = UDim.new(0, 4)
		local nL = Instance.new("TextLabel", row)
		nL.Size = UDim2.new(0.30, -4, 1, 0)
		nL.Position = UDim2.new(0.10, 4, 0, 0)
		nL.BackgroundTransparency = 1
		nL.Text = inst.Name
		nL.TextColor3 = C.TXT
		nL.TextSize = 11
		nL.Font = Enum.Font.Gotham
		nL.TextXAlignment = Enum.TextXAlignment.Left
		nL.TextTruncate = Enum.TextTruncate.AtEnd
		local iL = Instance.new("TextLabel", row)
		iL.Size = UDim2.new(0.30, -4, 1, 0)
		iL.Position = UDim2.new(0.40, 2, 0, 0)
		iL.BackgroundTransparency = 1
		iL.Text = m.id
		iL.TextColor3 = C.A3
		iL.TextSize = 10
		iL.Font = Enum.Font.Code
		iL.TextXAlignment = Enum.TextXAlignment.Left
		iL.TextTruncate = Enum.TextTruncate.AtEnd
		local tL = Instance.new("TextLabel", row)
		tL.Size = UDim2.new(0.16, -4, 1, 0)
		tL.Position = UDim2.new(0.70, 2, 0, 0)
		tL.BackgroundTransparency = 1
		tL.Text = m.instType
		tL.TextColor3 = C.SUB
		tL.TextSize = 9
		tL.Font = Enum.Font.Gotham
		tL.TextTruncate = Enum.TextTruncate.AtEnd
		local pL = Instance.new("TextLabel", row)
		pL.Size = UDim2.new(0.14, -6, 1, 0)
		pL.Position = UDim2.new(0.86, 2, 0, 0)
		pL.BackgroundTransparency = 1
		pL.Text = m.lastName
		pL.TextColor3 = Color3.fromRGB(115, 105, 155)
		pL.TextSize = 9
		pL.Font = Enum.Font.Code
		pL.TextTruncate = Enum.TextTruncate.AtEnd
		row.MouseButton1Click:Connect(function()
			if selectedImgRow then selectedImgRow.BackgroundColor3 = C.BG end
			row.BackgroundColor3 = C.SEL
			selectedImgRow = row
			setImgSel(inst)
		end)
		row.MouseEnter:Connect(function()
			if row ~= selectedImgRow then row.BackgroundColor3 = C.HOV end
		end)
		row.MouseLeave:Connect(function()
			if row ~= selectedImgRow then row.BackgroundColor3 = C.BG end
		end)
		if n % 12 == 0 then
			isf.CanvasSize = UDim2.new(0, 0, 0, isfl.AbsoluteContentSize.Y)
			task.wait()
		end
	end
	if imgRebuildId == myId then
		isf.CanvasSize = UDim2.new(0, 0, 0, isfl.AbsoluteContentSize.Y)
	end
end

local function doImageScan()
	if imgScanning then return end
	imgScanning = true
	iRefreshBtn.Text = "Scanning..."
	iRefreshBtn.BackgroundColor3 = C.ORG
	allImages = {}
	imageMeta = {}
	seenImgIds = {}
	clearImgSel()
	statusL.Text = "Scanning for images..."
	local scanN = 0
	local function recurse(parent)
		local ok, ch = pcall(parent.GetChildren, parent)
		if not ok then return end
		for _, v in ipairs(ch) do
			pcall(function()
				if v:IsA("ImageLabel") or v:IsA("ImageButton") or v:IsA("Decal")
				or v:IsA("Texture") or v:IsA("SpecialMesh") or v:IsA("MeshPart") then
					if cacheImgMeta(v) then
						local m = imageMeta[v]
						if not seenImgIds[m.id] then
							seenImgIds[m.id] = true
							table.insert(allImages, v)
							scanN = scanN + 1
							if scanN % 5 == 0 then
								statusL.Text = "Found Image  (ID: " .. m.id .. ")"
								task.wait()
							end
						end
					end
				end
			end)
			pcall(function()
				if #v:GetChildren() > 0 then recurse(v) end
			end)
		end
	end
	recurse(workspace)
	pcall(function() recurse(lp.PlayerGui) end)
	pcall(function() recurse(game:GetService("CoreGui")) end)
	pcall(function() recurse(game:GetService("StarterGui")) end)
	pcall(function() recurse(game:GetService("ReplicatedStorage")) end)
	pcall(function() recurse(game:GetService("Lighting")) end)
	task.spawn(imgRebuild)
	task.wait(2)
	statusL.Text = ""
	iRefreshBtn.Text = "Refresh List"
	iRefreshBtn.BackgroundColor3 = C.A2
	imgScanning = false
end

local function setImgFilter(f)
	activeImgFilter = f
	ifAll.BackgroundColor3      = f == "All Images"  and C.A1 or C.PANEL
	ifDecal.BackgroundColor3    = f == "Decal"       and C.A1 or C.PANEL
	ifTexture.BackgroundColor3  = f == "Texture"     and C.A1 or C.PANEL
	ifImgLabel.BackgroundColor3 = f == "ImageLabel"  and C.A1 or C.PANEL
	task.spawn(imgRebuild)
end

ifAll.MouseButton1Click:Connect(function() setImgFilter("All Images") end)
ifDecal.MouseButton1Click:Connect(function() setImgFilter("Decal") end)
ifTexture.MouseButton1Click:Connect(function() setImgFilter("Texture") end)
ifImgLabel.MouseButton1Click:Connect(function() setImgFilter("ImageLabel") end)
iRefreshBtn.MouseButton1Click:Connect(function() task.spawn(doImageScan) end)

isbBox:GetPropertyChangedSignal("Text"):Connect(function()
	imgSearchQuery = isbBox.Text
	if imgSearchTimer then task.cancel(imgSearchTimer) end
	imgSearchTimer = task.delay(0.3, function() task.spawn(imgRebuild) end)
end)

local iCopying = false
iCopyBtn.MouseButton1Click:Connect(function()
	if not selectedImage or iCopying then return end
	local m = imageMeta[selectedImage]
	if not m then return end
	iCopying = true
	pcall(setclipboard, m.id)
	iCopyBtn.Text = "Copied!"
	task.wait(1.2)
	iCopyBtn.Text = "Copy Asset Id"
	iCopying = false
end)

-- ================================================================
-- TAB SWITCHING
-- ================================================================
local activeTab = "Audio"

local function switchTab(tab)
	activeTab = tab
	tabAudioBtn.BackgroundColor3  = tab == "Audio"  and C.A1 or C.PANEL
	tabImageBtn.BackgroundColor3  = tab == "Image"  and C.A1 or C.PANEL
	tabOthersBtn.BackgroundColor3 = tab == "Others" and C.A1 or C.PANEL
	audioBody.Visible  = tab == "Audio"
	imageBody.Visible  = tab == "Image"
	othersBody.Visible = tab == "Others"
	if tab == "Image" and #allImages == 0 and not imgScanning then
		task.spawn(doImageScan)
	end
end

tabAudioBtn.MouseButton1Click:Connect(function() switchTab("Audio") end)
tabImageBtn.MouseButton1Click:Connect(function() switchTab("Image") end)
tabOthersBtn.MouseButton1Click:Connect(function() switchTab("Others") end)

-- ================================================================
-- MINIMIZE + DRAG
-- ================================================================
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	TweenService:Create(mf, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = minimized and UDim2.new(0, W, 0, TH) or UDim2.new(0, W, 0, H)
	}):Play()
	minBtn.Text = minimized and "=" or "-"
end)

local dragging, dragInput, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	mf.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + delta.X,
		startPos.Y.Scale, startPos.Y.Offset + delta.Y
	)
end

tbar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging  = true
		dragStart = input.Position
		startPos  = mf.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

tbar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateDrag(input)
	end
end)

task.spawn(doScan)
