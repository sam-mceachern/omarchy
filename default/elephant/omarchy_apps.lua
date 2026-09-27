-- Applications provider for the Walker "inventory" launcher.
--
-- Exists instead of the built-in desktopapplications provider because only a
-- custom provider can emit a preview, which is what fills the detail panel.
-- The heavy lifting (parsing .desktop files, resolving icons, rendering the
-- panel image) lives in omarchy-walker-app-entries so it can be run and tested
-- on its own; this just adapts its TSV output into elephant entries.
--
-- Excluded apps are kept out of the grid at rest and only surface once you
-- search. That needs the live query, which means Cache must stay false:
-- with Cache=true GetEntries is called exactly once, at elephant startup, with
-- an empty query. The cost of that is this function running on every keystroke,
-- and its lua state being thrown away between calls -- locals do NOT persist,
-- so nothing can be memoised here. Hence: no forking per keypress, just a read
-- of the manifest that omarchy-walker-app-entries maintains.

Name = "omarchyapps"
NamePretty = "Applications"
Icon = "applications-other"
Cache = false
HideFromProviderlist = true
SearchName = true

-- Named action: walker renders each action as a clickable KeybindButton, which
-- is what gives the detail panel its "open" button.
Actions = {
  open = "uwsm-app -- gtk-launch %VALUE%",
}

local HOME = os.getenv("HOME") or ""
local OMARCHY_PATH = os.getenv("OMARCHY_PATH") or (HOME .. "/.local/share/omarchy")
local MANIFEST = (os.getenv("XDG_CACHE_HOME") or (HOME .. "/.cache"))
  .. "/omarchy/walker-app-entries.tsv"

-- Repo baseline first, personal list second; an app on either is excluded.
local EXCLUDE_FILES = {
  OMARCHY_PATH .. "/default/walker/app-exclude.txt",
  (os.getenv("XDG_CONFIG_HOME") or (HOME .. "/.config")) .. "/omarchy/walker-app-exclude.txt",
}

-- A single character matches most of the list, so revealing excluded apps on
-- the first keypress would make the grid jump around while you are still
-- typing. Two characters is enough to be deliberate.
local MIN_SEARCH_CHARS = 2

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Keyed by lowercased name AND lowercased .desktop id, so either identifies an
-- app. Names are what a person recognises; ids survive a rename.
local function load_exclusions()
  local set = {}
  for _, path in ipairs(EXCLUDE_FILES) do
    local f = io.open(path, "r")
    if f then
      for line in f:lines() do
        line = trim(line:gsub("#.*", ""))
        if line ~= "" then set[line:lower()] = true end
      end
      f:close()
    end
  end
  return set
end

local function read_manifest()
  local rows = {}
  local f = io.open(MANIFEST, "r")
  if not f then return rows end
  for line in f:lines() do
    local id, name, sub, icon, preview =
      line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if id and name and name ~= "" then
      rows[#rows + 1] = { id = id, name = name, sub = sub, icon = icon, preview = preview }
    end
  end
  f:close()
  return rows
end

function GetEntries(query)
  query = query or ""

  -- Only on the empty query, i.e. when the launcher has just opened. --sync
  -- returns immediately unless the installed apps or the theme changed, so
  -- this is a few milliseconds in the normal case and never runs mid-search.
  if query == "" then
    local h = io.popen("omarchy-walker-app-entries --sync 2>/dev/null")
    if h then h:read("*a"); h:close() end
  end

  local searching = #query >= MIN_SEARCH_CHARS
  local excluded = (not searching) and load_exclusions() or nil

  local entries = {}
  for _, row in ipairs(read_manifest()) do
    -- While searching, everything is offered and elephant does the matching.
    if searching
      or not (excluded[row.name:lower()] or excluded[row.id:lower()]) then
      local entry = {
        Text = row.name,
        Subtext = row.sub,
        Value = row.id,
        Icon = row.icon,
      }
      -- The panel image is icon + name + description composited together; a
      -- preview is either text or a file, so this is the only way to show both.
      if row.preview and row.preview ~= "" then
        entry.Preview = row.preview
        entry.PreviewType = "file"
      end
      entries[#entries + 1] = entry
    end
  end
  return entries
end
