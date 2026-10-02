# Copy-WithProgress

Copies folders with Robocopy while showing a PowerShell progress bar, with a nested bar per folder when copying
several.

```
Copying files...
    Copied 1204 of 3310 files (1.82 GiB of 4.6 GiB)
    [ooooooooooooooooooooooooo                                        ]
    Copying "Photos"
        Copied 312 of 958 files (402.5 MiB of 1.21 GiB)
        [ooooooooooooooooooooo                                        ]
```

> [!WARNING]
> By default the folders are **mirrored** with Robocopy's `/MIR`: files in the destination that no longer exist in
> the source are deleted. Use `-NoMirror` to copy without deleting anything.

## Commands

| Command                   | Description                                                                         |
| ------------------------- | ----------------------------------------------------------------------------------- |
| `Copy-WithProgress`       | Copies one or several folders with Robocopy and returns the result of each job.     |
| `Convert-BytesToReadable` | Formats a number of bytes with binary units, such as `3.81 MiB`. Alias: `Convert-Bytes`. |

Both commands have help with examples, for example `Get-Help Copy-WithProgress -Examples`.

## Installation

Clone the repository into a folder named `Copy-WithProgress` in one of your module paths:

```powershell
git clone https://github.com/DoubleThePsycho/Copy-WithProgress "$HOME\Documents\PowerShell\Modules\Copy-WithProgress"
Import-Module Copy-WithProgress
```

For Windows PowerShell 5.1, use `$HOME\Documents\WindowsPowerShell\Modules\Copy-WithProgress` instead.

Requires Windows, since it runs `robocopy.exe`.

## Usage

Copy a single folder:

```powershell
Copy-WithProgress C:\Projects D:\Backup\Projects -Name Projects
```

Copy several folders, as hashtables or objects with `Name`, `Source` and `Destination`:

```powershell
$Jobs = @(
	@{ Name = 'Documents'; Source = "$HOME\Documents"; Destination = 'D:\Backup\Documents' }
	@{ Name = 'Photos';    Source = "$HOME\Pictures";  Destination = 'D:\Backup\Pictures' }
)

$Jobs | Copy-WithProgress -NoMirror -TimeOut 600
```

Each job returns its result:

```
Name      Success TimeSpan
----      ------- --------
Documents    True 00:01:02.4180311
Photos      False 00:10:00.0124570
```

`Success` is `$false` when the job timed out, or when Robocopy reported that files failed to copy (exit code 8 or
higher).

### Timeouts

Robocopy keeps retrying files it can't open, so copying files that an application is still writing to can hang
forever. `-TimeOut` stops a job after the given number of seconds, writes a warning, and moves on to the next job.

## License

[MIT](LICENSE)
