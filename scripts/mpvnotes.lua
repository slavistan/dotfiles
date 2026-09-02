-- mpvnotes: zeitmarkierte Notizen zu einem mpv-Stream.
--
-- Wird vom Wrapper `mpvnotes` per `-c dofile()` geladen. Ohne die Variable
-- MPVNOTES_JSON definiert die Datei nur ihre Funktionen und tut sonst nichts,
-- damit man sie einzeln testen kann.
--
-- mpv laeuft in einem Terminal-Split: dort gilt seine eigene Steuerung, inkl.
-- Maus im OSC, falls ein Fenster aufgeht (Video oder Cover). Der IPC-Socket
-- dient nur dazu, dass nvim die Position kennt und dorthin springen kann.

local M = {}

-- ------------------------------------------------------------- Einstellungen

-- Reaktionszeit in Sekunden: so viel wird vom eingefuegten Timestamp
-- abgezogen, weil der Hotkey immer erst nach der interessanten Stelle kommt.
-- 0 schaltet die Korrektur ab.
M.lead = 3

-- Was der Timestamp-Hotkey schreibt. '%s' ist der Zeitpunkt als HH:MM:SS.
M.stamp_format = '%s'

M.split_height = 8

-- Hervorhebung der Timestamps. Jede Highlight-Gruppe ist erlaubt: 'Special'
-- ist in milton cyan-kursiv, 'Number' violett, 'Comment' daempft sie statt sie
-- hervorzuheben. Leerer String schaltet es ab. Feiner justieren geht auch per
-- ':hi MpvnotesStamp ...', das gewinnt gegen die Voreinstellung hier.
M.stamp_hl = 'Special'

-- Die Bindings. Reihenfolge, Taste und Beschreibung stehen hier; daraus
-- entstehen sowohl die Mappings als auch das Cheat Sheet, es gibt also keine
-- zweite Stelle, die veralten kann. `name` verweist auf handlers[] weiter unten.
M.bindings = {
  { name = 'stamp', key = '<C-l>', modes = { 'n', 'i' }, expr = true,
    desc = 'insert HH:MM:SS at the cursor (o<C-l> for a new line)' },
  { name = 'seek', key = '<C-j>', modes = { 'n' },
    desc = 'seek mpv to the timestamp under the cursor' },
  { name = 'next', key = '<C-n>', modes = { 'n' },
    desc = 'jump to the next timestamp line (n while search is on)' },
  { name = 'prev', key = '<C-p>', modes = { 'n' },
    desc = 'jump to the previous timestamp line (N while search is on)' },
  { name = 'help', key = '<F1>', modes = { 'n', 'i' },
    desc = 'this overview' },
}

-- Genau ein Format: HH:MM:SS am Zeilenanfang, abgeschlossen durch Zeilenende,
-- ':' oder Leerzeichen. Nichts Kuerzeres, nichts Inline -- dadurch gibt es pro
-- Zeile hoechstens einen Timestamp und keine Praefixe aus kaputten Tokens.
-- Der Abschluss steht im Lookahead, damit der Treffer nur den Zeitpunkt umfasst.
M.pat = [[\v^\d{2}:[0-5]\d:[0-5]\d%([: ]|$)@=]]

M.state = { pos = nil, chan = nil }
M._partial = '' -- angefangene JSON-Zeile zwischen zwei on_data-Aufrufen

-- ------------------------------------------------------------------ Formate

--- Sekunden -> 'HH:MM:SS'.
function M.fmt(sec)
  sec = math.max(0, math.floor(sec))
  return string.format('%02d:%02d:%02d',
    math.floor(sec / 3600), math.floor(sec % 3600 / 60), sec % 60)
end

--- 'HH:MM:SS' -> Sekunden, nil bei allem anderen.
function M.to_sec(ts)
  if type(ts) ~= 'string' then return nil end
  local h, m, s = ts:match('^(%d%d):([0-5]%d):([0-5]%d)$')
  if not h then return nil end
  return tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)
end

--- Der Timestamp am Anfang der Zeile (per Default der aktuellen), sonst nil.
function M.line_stamp(line)
  local hit = vim.fn.matchstr(line or vim.api.nvim_get_current_line(), M.pat)
  return hit ~= '' and hit or nil
end

--- Wie line_stamp, aber nur wenn der Cursor wirklich auf dem Timestamp steht.
--- Der Timestamp beginnt immer bei Spalte 0, also reicht der Vergleich mit
--- seiner Laenge. So passt es zu <C-n>/<C-p>, die genau dort landen.
function M.stamp_under_cursor()
  local stamp = M.line_stamp()
  if not stamp then return nil end
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return col < #stamp and stamp or nil
end

-- --------------------------------------------------------------------- IPC

local function send(tbl)
  if not M.state.chan then return false end
  return pcall(vim.fn.chansend, M.state.chan, vim.json.encode(tbl) .. '\n')
end
M.send = send

-- vim.json.decode macht aus JSON-null ein vim.NIL, und das ist in Lua wahr.
local function num(v)
  return type(v) == 'number' and v or nil
end

local function on_data(_, data)
  if #data == 1 and data[1] == '' then -- Socket zu, mpv ist weg
    M.state.chan = nil
    return
  end
  data[1] = M._partial .. data[1]
  M._partial = table.remove(data) -- letzte Zeile ist unvollstaendig
  for _, line in ipairs(data) do
    local ok, msg = pcall(vim.json.decode, line)
    if ok and msg.event == 'property-change' then
      if msg.name == 'time-pos' then
        M.state.pos = num(msg.data)
      end
    end
  end
end

--- Verbindet sich mit dem Socket, sobald mpv ihn angelegt hat.
function M.connect(socket, tries)
  local ok, id = pcall(vim.fn.sockconnect, 'pipe', socket, { on_data = on_data })
  if ok and type(id) == 'number' and id > 0 then
    M.state.chan = id
    send({ command = { 'observe_property', 1, 'time-pos' } })
    return
  end
  if tries > 0 then
    vim.defer_fn(function() M.connect(socket, tries - 1) end, 50)
  else
    vim.notify('mpvnotes: no IPC connection to mpv', vim.log.levels.WARN)
  end
end

-- --------------------------------------------------------------- Darstellung

--- Hebt die Timestamps im Notizfenster hervor.
--- Nutzt dasselbe M.pat wie Navigation und Sprung, es gibt also keine zweite
--- Timestamp-Definition, die abweichen koennte. matchadd ist fensterlokal, was
--- hier genau passt: das Notizfenster ist eindeutig und lebt so lange wie die
--- Sitzung. Prioritaet -1, damit die Suchhervorhebung obendrueber bleibt.
function M.highlight()
  if M.stamp_hl == '' then return end
  vim.api.nvim_set_hl(0, 'MpvnotesStamp', { link = M.stamp_hl, default = true })
  vim.fn.matchadd('MpvnotesStamp', M.pat, -1)
end

-- ---------------------------------------------------------------- Cheat Sheet

--- Baut die Zeilen der Uebersicht aus M.bindings.
function M.help_lines()
  local width = 0
  for _, b in ipairs(M.bindings) do
    width = math.max(width, #b.key)
  end
  local lines = { '' }
  for _, b in ipairs(M.bindings) do
    lines[#lines + 1] = string.format('  %-' .. width .. 's   %s', b.key, b.desc)
  end
  vim.list_extend(lines, {
    '',
    "  In the mpv split (<C-w>j) mpv's own key bindings apply.",
    '  q, <Esc> or <F1> closes this overview.',
    '',
  })
  return lines
end

local function open_help(back)
  local lines = M.help_lines()
  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = width + 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = 'wipe'

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = #lines,
    row = math.max(0, math.floor((vim.o.lines - #lines) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
    style = 'minimal',
    border = 'rounded',
    title = ' mpvnotes ',
    title_pos = 'center',
  })
  vim.wo[win].cursorline = false

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    -- Kam der Aufruf aus dem Insert-Mode, genau dorthin zurueck.
    if back and vim.api.nvim_win_is_valid(back.win) then
      vim.api.nvim_set_current_win(back.win)
      local line = vim.api.nvim_get_current_line()
      local col = math.min(back.cur[2], #line)
      vim.api.nvim_win_set_cursor(back.win, { back.cur[1], math.max(0, math.min(col, #line - 1)) })
      vim.cmd(col >= #line and 'startinsert!' or 'startinsert')
    end
  end

  for _, key in ipairs({ 'q', '<Esc>', '<F1>', '<CR>' }) do
    vim.keymap.set('n', key, close, { buffer = buf, nowait = true, silent = true })
  end
  vim.api.nvim_create_autocmd('BufLeave', { buffer = buf, once = true, callback = close })
end

function M.help()
  if vim.fn.mode() == 'i' then
    -- stopinsert wirkt erst nach dem Mapping, also das Fenster nachgelagert oeffnen
    local back = { win = vim.api.nvim_get_current_win(), cur = vim.api.nvim_win_get_cursor(0) }
    vim.cmd('stopinsert')
    vim.schedule(function() open_help(back) end)
  else
    open_help(nil)
  end
end

-- ------------------------------------------------------------------ Aktionen

--- Text fuer den Timestamp-Hotkey. Als <expr>-Mapping, damit das Einfuegen
--- exakt wie Tippen wirkt: im Insert-Mode nur der Text, im Normal-Mode 'i'
--- davor, sodass man anschliessend weiterschreibt.
function M.stamp_keys()
  if not M.state.pos then
    vim.schedule(function()
      vim.notify('mpvnotes: no playback position from mpv yet', vim.log.levels.WARN)
    end)
    return ''
  end
  local text = string.format(M.stamp_format, M.fmt(M.state.pos - M.lead))
  return vim.fn.mode() == 'n' and ('i' .. text) or text
end

function M.seek_at_cursor()
  local sec = M.to_sec(M.stamp_under_cursor())
  if sec then send({ command = { 'seek', sec, 'absolute' } }) end
end

--- Cursor zum naechsten/vorherigen Timestamp -- ausser die Suchhervorhebung
--- ist an, dann bleiben <C-n>/<C-p> bei ihrer Rolle als n/N.
local function hop(flags, on_hlsearch)
  return function()
    for _ = 1, vim.v.count1 do
      if vim.v.hlsearch == 1 then
        pcall(vim.cmd, 'normal! ' .. on_hlsearch)
      else
        vim.fn.search(M.pat, flags)
      end
    end
  end
end

local handlers = {
  stamp = M.stamp_keys,
  seek = M.seek_at_cursor,
  next = hop('', 'n'),
  prev = hop('b', 'N'),
  help = M.help,
}

-- -------------------------------------------------------------------- Start

function M.start(cfg)
  local buf = vim.api.nvim_get_current_buf() -- die Notizdatei, vor dem Split
  local notes_win = vim.api.nvim_get_current_win()
  M._partial = ''
  M.highlight() -- solange das Notizfenster noch das aktuelle ist

  local cmd = { 'mpv', '--input-ipc-server=' .. cfg.socket }
  vim.list_extend(cmd, cfg.mpv_args or {})
  table.insert(cmd, cfg.source)

  vim.cmd('botright ' .. M.split_height .. 'new')
  local mpv_win = vim.api.nvim_get_current_win()
  local mpv_buf = vim.api.nvim_get_current_buf()
  vim.wo.number = false
  vim.wo.signcolumn = 'no'
  vim.wo.winfixheight = true
  vim.fn.jobstart(cmd, { term = true })

  -- Im mpv-Fenster gibt es nichts zu navigieren, also kein Normal-Mode:
  -- wer hineinwechselt, tippt direkt in mpv. <C-w> bleibt als Ausweg, sonst
  -- kaeme man nur ueber <C-\><C-n> wieder heraus.
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], { buffer = mpv_buf })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
    buffer = mpv_buf,
    callback = function() vim.cmd('startinsert') end,
  })

  vim.cmd('wincmd p')

  -- Die Sitzung ist eine Einheit: geht eines der beiden Fenster zu, ist Schluss.
  -- 'confirm' fragt bei ungesicherten Notizen nach, statt sie wegzuwerfen.
  local closing = false
  vim.api.nvim_create_autocmd('WinClosed', {
    callback = function(args)
      local w = tonumber(args.match)
      if closing or (w ~= notes_win and w ~= mpv_win) then return end
      closing = true
      vim.schedule(function()
        pcall(vim.cmd, 'confirm qall')
        closing = false -- nur erreichbar, wenn abgebrochen wurde
      end)
    end,
  })

  M.connect(cfg.socket, 60) -- 60 x 50ms = 3s Geduld

  for _, b in ipairs(M.bindings) do
    vim.keymap.set(b.modes, b.key, handlers[b.name], {
      buffer = buf,
      silent = true,
      expr = b.expr,
      desc = 'mpvnotes: ' .. b.desc,
    })
  end

  -- Sauber beenden statt abschiessen, sonst schreibt save-position-on-quit
  -- die Abspielposition nicht weg.
  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function() send({ command = { 'quit' } }) end,
  })
end

local raw = vim.env.MPVNOTES_JSON
if raw and raw ~= '' then
  M.start(vim.json.decode(raw))
end

return M
