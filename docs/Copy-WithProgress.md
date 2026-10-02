---
external help file: Copy-WithProgress-help.xml
Module Name: Copy-WithProgress
online version:
schema: 2.0.0
---

# Copy-WithProgress

## SYNOPSIS
Runs robocopy.exe paired up with a progress bar.

## SYNTAX

### Single (Default)
```
Copy-WithProgress [-Source] <String> [-Destination] <String> [[-Name] <String>] [-NoMirror] [-TimeOut <Int32>]
 [-ReportGap <Int32>] [<CommonParameters>]
```

### Multiple
```
Copy-WithProgress [-Object] <ArrayList> [-NoMirror] [-TimeOut <Int32>] [-ReportGap <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Uses RoboCopy to copy a single or multiple folders, while displaying a dynamic progress bar.

Before copying, every job is scanned to count the files and bytes to copy.
The main progress bar shows the progress of all jobs, and when copying several folders, a nested progress bar shows the current job.

By default the folders are mirrored with /MIR: files in the destination that no longer exist in the source are DELETED.
Use -NoMirror to copy without deleting anything.

When done, one object per job is returned, telling if the job succeeded and how long it took.

## EXAMPLES

### Example 1 - Copy a single folder.
```powershell
PS C:\> Copy-WithProgress -Source C:\Projects -Destination D:\Backup\Projects -Name Projects

Name     Success TimeSpan
----     ------- --------
Projects    True 00:00:12.3456789
```

This example mirrors C:\Projects to D:\Backup\Projects.

### Example 2 - Copy without deleting.
```powershell
PS C:\> Copy-WithProgress C:\Photos D:\Photos -NoMirror
```

This example copies new and changed files from C:\Photos to D:\Photos, and keeps files that only exist in D:\Photos.

### Example 3 - Copy multiple folders.
```powershell
PS C:\> Copy-WithProgress -Object @(
	@{ Name = "Entry 1";    Source = [Source 1];    Destination = [Destination 1] }
	@{ Name = "Entry 2";    Source = [Source 2];    Destination = [Destination 2] }
	@{ Name = "Entry 3";    Source = [Source 3];    Destination = [Destination 3] }
)
```

This example runs through the list of hashtables, copying them one by one from [Source] to [Destination] while displaying the [Name] in the progress bar.

### Example 4 - Copy multiple folders through the pipeline, with a timeout.
```powershell
PS C:\> $Jobs | Copy-WithProgress -TimeOut 600 | Where-Object { -not $_.Success }
```

This example copies every job in $Jobs, gives up on any job still running after 10 minutes, and lists the jobs that failed.

## PARAMETERS

### -Source
For single copy job, input path to source folder.

```yaml
Type: String
Parameter Sets: Single
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Destination
For single copy job, input path to destination folder.

```yaml
Type: String
Parameter Sets: Single
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
For single copy job, name to display in the progress bar and in the returned object.

```yaml
Type: String
Parameter Sets: Single
Aliases:

Required: False
Position: 2
Default value: Single job
Accept pipeline input: False
Accept wildcard characters: False
```

### -Object
For multiple copy jobs, a list of hashtables or objects with the properties Name, Source and Destination.

```yaml
Type: ArrayList
Parameter Sets: Multiple
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -NoMirror
Copy with /E instead of /MIR, so files in the destination that do not exist in the source are kept instead of deleted.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeOut
Set a timeout, in seconds, for how long to attempt a job before giving up and proceeding.

Some files/folders will not copy if the application is active, this is a bypass.
If not specified, RoboCopy will keep on trying to copy the files forever.
A job that times out is returned with Success set to $false.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ReportGap
How many milliseconds to wait between each progress bar update.

Lower values update the progress bar more often, at the cost of more CPU use.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 200
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Collections.ArrayList
A list of hashtables or objects with the properties Name, Source and Destination.

## OUTPUTS

### System.Management.Automation.PSCustomObject
One object per job, with the properties Name, Success and TimeSpan.
Success is $false when the job timed out, or when RoboCopy returned an exit code of 8 or higher.

## NOTES
This is primarily a helper-function for my "PSDeepFreezeUtils" project,
but the function is without dependencies and can be used on its own.

Requires robocopy.exe, which is included in Windows.

Disclaimer:

The code is provided "as is", with all possible faults,
defects or errors, and without warranty of any kind.
Use this script at your own risk.

(c) 2025-2026 DoubleThePsycho. Licensed under the MIT License.

## RELATED LINKS

[Developer's Github:](https://github.com/DoubleThePsycho)

[RoboCopy:](https://learn.microsoft.com/windows-server/administration/windows-commands/robocopy)

[Convert-BytesToReadable](Convert-BytesToReadable.md)
