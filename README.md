# Recursive Text Search Bash Script

A Bash script that recursively searches for files within a specified directory, finds all occurrences of given text strings within those files, and reports the matches.

> [!NOTE]
> This script is based on **Replacer** (https://github.com/pixelotes/replacer).

## Features

* **Recursive Search**: Traverses all subdirectories.
* **Multiple Search Terms**: Search for multiple strings at once.
* **Occurrence Reporting**: Reports the number of matches per file and a total summary.
* **Review Mode**: Shows matched lines with reverse-video highlighting (enabled by default).
* **Handles Filenames with Spaces**: Uses `find ... -print0` and `read -d $'\0'` for robust filename handling.
* **Text File Detection**: Uses `file --mime-type` to ensure only text files are processed.
* **Extension Filtering**: Restrict processing to files with specific extensions (`--ext=txt,md`).
* **Case-Insensitive Matching**: Search text ignoring case (`--ignore-case`).
* **Ignore Binaries**: Detects and ignores binary files (`--ignore-binaries`).
* **Logging Support**: Outputs to a log file (`--log=path`).
* **Help Option**: Provides a detailed help message with `--help` or `-h`.

## Prerequisites

* A Bash shell (version 4.0+ recommended).

## Installation

1. Download the `searcher.sh` script.
2. Make it executable:

```bash
chmod +x searcher.sh
```

## Usage

```bash
./searcher.sh [OPTIONS] -s <text_to_find> [-s <more_text> ...] <directory>
```

### Arguments

* `-s`, `--string <text>`: The text string to search for. Can be specified multiple times to search for different terms simultaneously.
* `<directory>`: The path to the root directory where the script will start its recursive search.

### Options

* `--help`, `-h`: Display the help message and exit.
* `--depth`: Specifies the folder depth for searching files.
* `--ext=ext1,ext2`: Only process files with the given extensions.
* `--ignore-case`: Match text regardless of case.
* `--ignore-binaries`: Ignores binary files.
* `--log=FILE`: Write the script output to a log file.

## Example

To find all occurrences of "password", "passwd", or "secret" in all `.txt` and `.json` files within the `.` directory, ignoring case and binary files:

```bash
./searcher.sh --ignore-case --ignore-binaries -s "password" -s "passwd" -s "secret" --ext=txt,json .
```

## Contributing

Contributions, bug reports, and feature requests are welcome! Please open an issue or submit a pull request.

## License

This project is published under the [MIT License](LICENSE).
