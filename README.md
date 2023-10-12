# boltviewer
boltviewer is a neovim plugin for viewing boltdb files.

## Install
the plugin uses noevim's go-client for accessing boltdb and interacting with neovim at the same time. So, we need to install the golang executable with

```shell
go install github.com/asxalex123/boltviewer@main
```

This will install the go-plugin in your "$GOPATH/bin", make sure the directory is in `$PATH`

Then install the vim plugin with neovim's lazy.nvim:

```lua
-- ~/.config/nvim/lua/plugins/boltviewer.lua
return {
    {"asxalex123/boltviewer.nvim"},
}
```

Start nvim and lazy.nvim will do the rest.

## keybindings
After installed, while open or create file with suffix `.boltdb`, the plugin will show the content in the format below, instead of the binary:

```
bucket-name1
    key1 => value1
    key2 => value2
bucket-name2
    key3 => value3
    key4 => value4
```

* the `<leader>bib` stands for `bolt insert bucket`, this will prompt the bucket name for insert, edit it and press enter in normal mode, boltviewer will insert bucket in the real boltdb.
* the `<leader>bie` stands for `bolt insert entry`, should insert `key => value` in the prompt and press enter in normal mode for inserting entry in the bucket(the bucket is refered which above the entry editted)
* the `<leader>bm` will modify the entry under the cursor, the `key => new value` format, which the key should be same with the previous one.
* the `<leader>bd` will delete the line under the cursor, if the line is a bucketname, the bucket should contain no entry.

the `bc` key binding is interpreted as `bolt create entry(or bucket)`, while `bd` stands for `bolt delete entry (or bucket)`. A line starts with white space is treated as an entry(which should in the form of `key => value`), and other line is treated as a bucket name.

if we hit `bc` with cursor on a bucket line, a bucket will be created in boltdb, if cursor on an entry line, an entry will be created.

if we hit `bd` with cursor on a bucket line, the bucket will be dropped if the bucket has no entry, otherwise, the action will fail.

if `bd` is hit with cursor on an entry line, the entry will be deleted from the bucket.

