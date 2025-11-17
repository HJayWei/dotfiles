-- Ref: https://github.com/vuejs/language-tools/wiki/Neovim

-- Expand ~ and convert to absolute path
local function expand_path(p)
  if not p or p == "" then
    return p
  end
  return vim.fn.fnamemodify(vim.fn.expand(p), ":p")
end

-- Get current effective cwd (based on window/tab/global scope)
local function current_cwd()
  return expand_path(vim.fn.getcwd())
end

-- Derive project root based on current cwd (using package.json/tsconfig.json/.git)
local function find_project_root(start)
  -- Use built-in file search method, traverse upwards
  local markers = { "package.json", "tsconfig.json", ".git" }
  local dir = expand_path(start)
  while dir and dir ~= "/" do
    for _, m in ipairs(markers) do
      if vim.fn.filereadable(dir .. "/" .. m) == 1 or vim.fn.isdirectory(dir .. "/" .. m) == 1 then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return expand_path(start)
end

-- Dynamically get @vue/typescript-plugin path
local function get_vue_plugin_path()
  local cwd = current_cwd()
  local root = find_project_root(cwd)
  local candidate = root .. "node_modules/@vue/language-server"
  if vim.fn.isdirectory(candidate) == 1 then
    return candidate
  end
  -- Common monorepo subdirectory fallbacks
  local sub_candidates = {
    root .. "/frontend/node_modules/@vue/language-server",
    root .. "/app/node_modules/@vue/language-server",
    cwd .. "/node_modules/@vue/language-server",
  }
  for _, c in ipairs(sub_candidates) do
    if vim.fn.isdirectory(c) == 1 then
      return c
    end
  end
  -- Return expected path even if it doesn't exist (will take effect after installation)
  return candidate
end

-- Build configuration tables for three servers based on current cwd
local function build_configs()
  local vue_language_server_path = get_vue_plugin_path()
  local tsserver_filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" }

  local vue_plugin = {
    name = "@vue/typescript-plugin",
    location = vue_language_server_path,
    languages = { "vue" },
    configNamespace = "typescript",
  }

  local vtsls_config = {
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = {
            vue_plugin,
          },
        },
      },
    },
    filetypes = tsserver_filetypes,
  }

  local ts_ls_config = {
    init_options = {
      plugins = {
        vue_plugin,
      },
    },
    filetypes = tsserver_filetypes,
  }

  local vue_ls_config = {}

  return vtsls_config, ts_ls_config, vue_ls_config, vue_language_server_path
end

-- Extract vue plugin path from currently running client (if any)
local function get_running_plugin_location(client_name)
  for _, client in pairs(vim.lsp.get_active_clients()) do
    if client.name == client_name then
      local ok, settings = pcall(function()
        return client.config.settings
      end)
      if ok and settings and settings.vtsls and settings.vtsls.tsserver then
        local plugins = settings.vtsls.tsserver.globalPlugins
        if type(plugins) == "table" then
          for _, p in ipairs(plugins) do
            if p.name == "@vue/typescript-plugin" and type(p.location) == "string" then
              return expand_path(p.location)
            end
          end
        end
      end
      -- ts_ls configuration is in init_options.plugins
      local ok2, init = pcall(function()
        return client.config.init_options
      end)
      if ok2 and init and type(init.plugins) == "table" then
        for _, p in ipairs(init.plugins) do
          if p.name == "@vue/typescript-plugin" and type(p.location) == "string" then
            return expand_path(p.location)
          end
        end
      end
    end
  end
  return nil
end

-- Configure and start (restart if already running with different path)
local restarting = false
local function setup_or_restart_servers()
  if restarting then
    return
  end

  local vtsls_config, ts_ls_config, vue_ls_config, desired = build_configs()
  desired = expand_path(desired)

  local current_vtsls = get_running_plugin_location("vtsls")
  local need_restart_vtsls = current_vtsls and current_vtsls ~= desired

  -- Apply config first (will overwrite existing)
  vim.lsp.config("vtsls", vtsls_config)
  vim.lsp.config("vue_ls", vue_ls_config)
  vim.lsp.config("ts_ls", ts_ls_config)

  if not current_vtsls then
    -- Not started yet, enable directly
    vim.lsp.enable({ "vtsls", "vue_ls" })
    vim.notify("LSP started with Vue plugin: " .. desired, vim.log.levels.INFO)
    return
  end

  if need_restart_vtsls then
    restarting = true
    vim.notify(
      ("vtsls restarting with new Vue plugin path\nold: %s\nnew: %s"):format(current_vtsls, desired),
      vim.log.levels.WARN
    )
    -- Stop corresponding client
    for _, client in pairs(vim.lsp.get_active_clients()) do
      if client.name == "vtsls" then
        client.stop()
      end
    end
    -- Wait before re-enabling to avoid race condition
    vim.defer_fn(function()
      vim.lsp.enable({ "vtsls", "vue_ls" })
      restarting = false
      vim.notify("vtsls restarted with Vue plugin: " .. desired, vim.log.levels.INFO)
    end, 200)
  end
end

-- Start after first GUI/UI entry to avoid early cwd errors in neovide
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    setup_or_restart_servers()
  end,
})

-- When directory changes, rebuild path based on new cwd and restart
vim.api.nvim_create_autocmd("DirChanged", {
  callback = function()
    setup_or_restart_servers()
  end,
})
