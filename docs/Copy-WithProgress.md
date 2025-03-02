---
external help file: Copy-WithProgress-help.xml
Module Name: Copy-WithProgress
online version:
schema: 2.0.0
---

# Copy-WithProgress

## SYNOPSIS
Runs robocopy.exe paired up with a progress bar.

## DESCRIPTION
Uses RoboCopy to copy a single or multiple folders, while displaying a dynamic progress bar.

## SYNTAX

### Single (Default)
```powershell
Copy-WithProgress [-Source] <String> [-Destination] <String> [-Name <String>] [-TimeOut <Int32>] [-ReportGap <Int32>] [<CommonParameters>]
```

### Multiple
```powershell
Copy-WithProgress -Object <ArrayList> [-TimeOut <Int32>] [-ReportGap <Int32>] [<CommonParameters>]
```

## EXAMPLES

### Example 1 - Copy a single folder.
```powershell
PS C:\> Copy-WithProgress -Source [SourcePath] -Destination [DestinationPath] -Name [JobName]
```

```
This example copies a single entry from -Source to -Destination.
```

### Example 2 - Copy multiple folders.
```powershell
PS C:\> Copy-WithProgress -Object @(
	@{ Name = "Entry 1";    Source = [Source 1];    Destination = [Destination 1] }
	@{ Name = "Entry 2";    Source = [Source 2];    Destination = [Destination 2] }
	@{ Name = "Entry 3";    Source = [Source 3];    Destination = [Destination 3] }
)
```

This example runs throug the list of hashtables, copying them one by one from [Source] to [Destination] while displaying the [Name] in the progress bar.

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
For single copy job, name to display in the progress bar.

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

### -Object
For multiple copy jobs, a list of names, sources and destinations.

```yaml
Type: ArrayList
Parameter Sets: Multiple
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -TimeOut
Set a timeout for how long to attempt a job before giving up and proceeding.

Some files/folders will not copy if the application is active, this is a bypass.
If not specified, RoboCopy will keep on trying to copy the files forever.

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
When copying to another network station, simulate lower speeds to get a proper look at the function in action.

(I have not been able to test this to see if it works.)

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [System.String] for -Source and -Destination
### [System.Collections.ArrayList] containing [System.Collections.Hashtable]

## OUTPUTS

### The function doesn't output anything, it summons RoboCopy.exe to copy specified folders.

## NOTES
This is primarily a helper-function for my "PSDeepFreezeUtils" project,
but the function is without dependencies and can be used on its own.

Disclaimer:

The code is provided "as is", with all possible faults,
defects or errors, and without warranty of any kind.
Use this script at your own risk.

(c) DoubleThePsycho Technologies.

## RELATED LINKS
[Developer's Github:](https://github.com/DoubleThePsycho)
[RoboCopy:](https://www.google.com/search?q=RoboCopy)
