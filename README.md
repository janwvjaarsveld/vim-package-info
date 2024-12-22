# vim-readme.nvim

A simple Neovim plugin to fetch and display a GitHub repository’s `README.md` in a floating window, using `curl`. Perfect for quickly checking a repository’s documentation without leaving your editor.

## Features

- Fetches a remote `README.md` from GitHub.
- Opens it in a floating window.
- Automatically tries common branch names (`main`, `master`, etc.) if the README isn’t found on the specified/default branch.
- Binds helpful keys (`q` to close the window, `o` to open the repo in your browser).
- Offers minimal configuration: you can customize floating window dimensions, border style, fallback branches, command name, and keymaps.

## Requirements

- Neovim 0.7 or higher (tested on the latest stable).
- `curl` installed on your system (used to fetch the remote file).

## Installation

Use your favorite plugin manager. For example, with [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  "janwvjaarsveld/vim-readme.nvim",
  config = function()
    require("vim-readme").setup()
  end
}
```

or with [lazy.nvim]("https://github.com.folke/lazy.nvim"):

```lua
{
  "janwvjaarsveld/vim-readme.nvim",
  config = function()
    require("vim-readme").setup()
  end
}
```

## Configuration

The plugin exports a setup function that accepts a Lua table. Any values you don’t specify will default to the values shown below:

```lua
require("vim-readme").setup({
  window = {
    width_ratio = 0.8,   -- Fraction of total columns
    height_ratio = 0.8,  -- Fraction of total lines
    border = "rounded",  -- Border style (e.g., "none", "single", "double", "rounded")
  },
  fallback_branches = { "main", "master" },
  command_name = "VimReadme", -- :Readme command
  key_bindings = {
    get_package_info = "<leader>vr",
    close = "q", -- Optional: Change close key to 'x'
    open_git = "o",
  },
})
```

## Usage

 1. Basic Command
    Run :VimReadme <username/repository> to fetch a GitHub repo’s README.md.
    Example:

    ```vim
    :VimReadme nvim-treesitter/nvim-treesitter
    ```

    2. Fetch from Text Under Cursor
    If you place your cursor on a string like "nvim-treesitter/nvim-treesitter" (quotes included), you can simply run:

    ```vim
    :VimReadme
    ```

    and it will parse the repository name from between the quotes and fetch the README automatically.

 3. Floating Window Behavior
 • Press q in Normal mode to close the floating window.
 • Press o in Normal mode to open the GitHub link in your browser (uses vim.ui.open()).

### Command Reference
- :<command_name> (by default, :VimReadme)
- :VimReadme <username/repository> – fetch the README.md for that repository.
- :VimReadme (with no args) – fetch from the string under your cursor (if quoted).

### Keymaps

By default, if you haven’t overridden them:
- ***Global***
  - <leader>vr – calls the :VimReadme command.
- ***Within the Floating Window***
  - q – closes the floating window (:bd!).
  - o – opens the repository on GitHub in your browser.

### Contributing

Contributions, bug reports, and feature requests are welcome! Here’s how you can help:

 1. [Fork the repository](https://github.com/janwvjaarsveld/vim-readme/fork).
 2. Create a new branch for your changes.
 3. Submit a Pull Request describing your changes.

License

[MIT](LICENSE) – this plugin is open-source and free to use or modify. Pull requests are always welcome!

Enjoy exploring repositories without leaving Neovim with vim-readme!
