return {
  "kappke/opencode.nvim",
  config = function()
    require("opencode").setup({
      side = "left",
      width = 50,
    })
  end,
}
