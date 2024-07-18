return {
  "mfussenegger/nvim-dap-python",
  ft = "python",
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    local path = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/vin/python"
    require("dap-python").setup(path)
  end,
}
