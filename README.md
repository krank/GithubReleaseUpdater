# GithubReleaseUpdater
This is a simple solution to when you just want a simple, quick and easy script to run that grabs the latest release from a github repo, extracts it and puts the new files in the right directory. I personally use it to keep my emulators up to date, but I imagine it could be useful for other stuff too.

## Usage
Place the ps1 file in a directory. Add a json file; you can use the template file from the repo. Modify it so it fits the project you want to download updates for.

Then just run `CheckNewVersion.ps1` from the commandline (or my preferred way; right clicking in explorer and "Run with powershell". This might require some additional tinkering with permissions, though. YMMV.)

## The config
The default is this:

```
{
  "name" : "Software name",
  "out_directory" : "./DirName/",
  "repo" : "githubuser/reponame",
  "file_to_date" : "filename.exe",
  "asset_name_regex" : ".",
  "include_drafts" : false,
  "include_prerelease" : false
}
```

Most of these should be self-explanatory.
- The script uses timestamps to determine if there's a new version; it compares the file_to_date inside the out_directory with the date of the asset.
- The script finds the first release that matches the requirements. By default this means not including draft or prereleases.
- It then finds the first asset whose name matches the regex. Use this to finds the Win64 binary or whatever it is you need.
- The script will download the zip as "tmp.zip" to the subfolder "temp", extract the contents to a subfolder called "temp/latest", then copy the files over to the out_directory, forcing overwrites. Then it removes the temp folder and its contents.

Here's a real world example of a config for [UZDoom]([link](https://github.com/UZDoom/uzdoom)):
```
{
  "name" : "UZDoom",
  "out_directory" : "./UZDoom/",
  "repo" : "uzdoom/uzdoom",
  "file_to_date" : "uzdoom.exe",
  "asset_name_regex" : "^Windows",
  "include_drafts" : false,
  "include_prerelease" : false
}
```

## Multiple configs

You can have multiple configs in the same json; just make the root element an array. For example, here's a config that pulls both [UZDoom]([link](https://github.com/UZDoom/uzdoom)) and [CXBX-reloaded]([link](https://github.com/cxbx-reloaded/cxbx-reloaded)):
```
[
  {
    "name": "CXBOX-reloaded",
    "out_directory": "./CXBX-reloaded/",
    "repo": "Cxbx-Reloaded/Cxbx-Reloaded",
    "file_to_date": "cxbx.exe",
    "asset_name_regex": "^CxbxReloaded",
    "include_drafts": false,
    "include_prerelease": true
  },
  {
    "name": "UZDoom",
    "out_directory": "./UZDoom/",
    "repo": "uzdoom/uzdoom",
    "file_to_date": "uzdoom.exe",
    "asset_name_regex": "^Windows",
    "include_drafts": false,
    "include_prerelease": false
  }
]
```

## Specify config by commandline

If you really want to, you can specify a json file manually:

`> CheckNewVersion.ps1 Marathon.json`