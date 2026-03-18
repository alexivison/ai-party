return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>" },
    },
  },
  {
    "vimpostor/vim-tpipeline",
    lazy = false,
  },
  -- Minimal lualine matching tmux dotbar (GitHub Dark Dimmed)
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local bg = "#22272e"
      local fg = "#636e7b"
      local fg_active = "#adbac7"
      local green = "#57ab5a"
      local blue = "#539bf5"
      local yellow = "#daaa3f"
      local red = "#e5534b"
      local purple = "#b083f0"

      local flat = { bg = bg, fg = fg }
      local theme = {
        normal = {
          a = { bg = bg, fg = blue, gui = "bold" },
          b = flat,
          c = flat,
        },
        insert = {
          a = { bg = bg, fg = green, gui = "bold" },
        },
        visual = {
          a = { bg = bg, fg = purple, gui = "bold" },
        },
        replace = {
          a = { bg = bg, fg = red, gui = "bold" },
        },
        command = {
          a = { bg = bg, fg = yellow, gui = "bold" },
        },
        inactive = {
          a = flat,
          b = flat,
          c = flat,
        },
      }

      opts.options = opts.options or {}
      opts.options.theme = theme
      opts.options.component_separators = ""
      opts.options.section_separators = ""
      opts.options.globalstatus = false

      opts.sections = {
        lualine_a = { { "mode" } },
        lualine_b = {},
        lualine_c = { { "filename", path = 1, color = { fg = fg } } },
        lualine_x = { { "diagnostics" } },
        lualine_y = { { "filetype", color = { fg = fg } } },
        lualine_z = { { "location", color = { fg = fg } } },
      }
      opts.inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      }

      vim.defer_fn(function()
        vim.opt.laststatus = 0
      end, 0)
    end,
  },
}
