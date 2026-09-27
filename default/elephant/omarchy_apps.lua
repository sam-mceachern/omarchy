-- Applications provider for the Walker "inventory" launcher.
--
-- Exists instead of the built-in desktopapplications provider because only a
-- custom provider can emit a preview, which is what fills the detail panel.
-- The heavy lifting (parsing .desktop files, resolving icons, rendering the
-- panel image) lives in omarchy-walker-app-entries so it can be run and tested
-- on its own; this just adapts its TSV output into elephant entries.

Name = "omarchyapps"
NamePretty = "Applications"
Icon = "applications-other"
Cache = true
HideFromProviderlist = true
SearchName = true

-- Named action: walker renders each action as a clickable KeybindButton, which
-- is what gives the detail panel its "open" button.
Actions = {
  open = "uwsm-app -- gtk-launch %VALUE%",
}

function GetEntries()
  local entries = {}
  local handle = io.popen("omarchy-walker-app-entries 2>/dev/null")
  if not handle then return entries end

  for line in handle:lines() do
    local id, name, sub, icon, preview =
      line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if id and name and name ~= "" then
      local entry = {
        Text = name,
        Subtext = sub,
        Value = id,
        Icon = icon,
      }
      -- The panel image is icon + name + description composited together; a
      -- preview is either text or a file, so this is the only way to show both.
      if preview and preview ~= "" then
        entry.Preview = preview
        entry.PreviewType = "file"
      end
      table.insert(entries, entry)
    end
  end
  handle:close()
  return entries
end
