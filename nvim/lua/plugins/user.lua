-- User plugins: additions and overrides beyond AstroNvim defaults.
-- Add new plugins by appending to the returned table.

---@type LazySpec
return {
  -- Colorscheme: Gruvbox (selected via astroui.lua)
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      contrast = "hard",
    },
  },

  -- Surround text objects: cs"' to change "foo" -> 'foo', ds( to delete (), ysiw" to wrap word in quotes
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    opts = {},
  },

  -- Flash: jump anywhere on screen with 2 keystrokes (s + label)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- Oil: edit the filesystem as a buffer (press `-` to open parent dir)
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
    },
    opts = {},
  },

  -- Harpoon: pin a few files and jump between them with <leader>1..4
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<Leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
      { "<Leader>hh", function() local h = require("harpoon"); h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon menu" },
      { "<Leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<Leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<Leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<Leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
  },

  -- TODO/FIXME/HACK/NOTE highlighting + project-wide listing via :TodoTelescope
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
