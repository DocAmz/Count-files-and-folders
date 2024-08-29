# Count-files-and-folders

This script counts files and folders within a specified directory and optionally excludes certain directories or files. It can also display subfolders up to a specified depth level.

## Usage

Before running the script, ensure it has executable permissions. You can set the permissions using the following command:

```bash
chmod +x count_files.sh
```

After setting the executable permissions, you can run the script as follows:

```bash
  ./count_files.sh [-p <directory>] [-s] [-l <level>] [-e <exclude-path>] [-h] [-v]
```

## Options

- `-p <directory>`: Directory to count files and folders in (default: ./)
- `-s`: Display subfolders with file and folder counts
- `-l <level>`: Display subfolders up to a specific depth level (default: all levels)
- `-e <exclude-path>`: Exclude specific subdirectories or files (can be used multiple times)
- `-h`: Display this help message
- `-v`: Display version information

## Examples

Example from the root directory:

```bash
  ./count_files.sh -p ./src -s -l 1 -e "/modules"
```

Example from a specific directory:

```bash
  ./count_files.sh -p /path/to/directory -s -l 2 -e "/modules" -e "/node_modules"
```

Example from package.json command :

```bash
  "scripts": {
    "count-files": "bash ./script/count_files.sh -p ./src -s -l 1 -e '/node_modules'"
  }
```

Example php command :

```bash
  php -r "echo shell_exec('bash ./script/count_files.sh -p ./src -s -l 1 -e \"/node_modules\"');"
```
