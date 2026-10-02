---
external help file: Convert-BytesToReadable-help.xml
Module Name: Copy-WithProgress
online version:
schema: 2.0.0
---

# Convert-BytesToReadable

## SYNOPSIS
Returns a string denoting human readable form of a number of bytes.

## SYNTAX

```
Convert-BytesToReadable [[-Value] <BigInteger>] [[-Alignment] <SByte>] [<CommonParameters>]
```

## DESCRIPTION
Returns a string denoting human readable form using binary (IEC) units for accuracy.

Binary units use powers of 1024, so 1 KiB is 1024 bytes, while 1 KB is only 1000 bytes.

The result is rounded to at most two decimals.

## EXAMPLES

### EXAMPLE 1 - Plain conversion.
```powershell
PS C:\> Convert-BytesToReadable 1125899906842624

1 PiB
```

### EXAMPLE 2 - Pipelined conversion.
```powershell
PS C:\> 4000000 | Convert-BytesToReadable

3.81 MiB
```

### EXAMPLE 3 - Conversion with math.
```powershell
PS C:\> Convert-BytesToReadable ([System.Math]::Pow(2, 120))

1048576 QiB
```

### EXAMPLE 4 - Include conversion in a sentence.
```powershell
PS C:\> Write-Host ('Total size: {0}' -f (Convert-BytesToReadable -Value 1125899906842624))

Total size: 1 PiB
```

### EXAMPLE 5 - Include conversion in a sentence + aligning number.
```powershell
PS C:\> Write-Host "Total size: $(Convert-BytesToReadable -Value 1125899906842624 -Alignment 5)"

Total size:     1 PiB
```

### EXAMPLE 6 - Some examples for you to try out!
```powershell
Convert-BytesToReadable -Value 4 -Alignment 9
Convert-BytesToReadable -Value 4000 -Alignment 9
Convert-BytesToReadable -Val 4000000 -Ali 9
Convert-BytesToReadable -V 4000000000 -A 9
Convert-BytesToReadable 40000000000000 -Alignment 9
Convert-BytesToReadable 40000000000000000 -Alignment 9
Convert-BytesToReadable 40000000000000000000 9
Convert-BytesToReadable 4000000000000000000000 9
Convert-BytesToReadable -Value 4000000000000000000000000 -Alignment 9
Convert-BytesToReadable -Value 4000000000000000000000000000 -Alignment 9
Convert-BytesToReadable -Value ([Int64]::MaxValue).ToString() -Alignment 9
Convert-BytesToReadable ([Decimal]::MaxValue).ToString() -Alignment 9
```

## PARAMETERS

### -Value
Number of bytes. Supports ridiculously high numbers.

Keep in mind that really large numbers are rounded off, since the value is converted to a double for the division.

```yaml
Type: BigInteger
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Alignment
Allows you to align the number as if using .PadLeft().

```yaml
Type: SByte
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Numerics.BigInteger
Supports ridiculously high numbers.

## OUTPUTS

### System.String
Human readable string denoting size.

## NOTES
This is primarily a helper-function for Copy-WithProgress,
but the function is without dependencies and can be used on its own.

The alias Convert-Bytes can be used instead of the full name.

Disclaimer:

The code is provided "as is", with all possible faults,
defects or errors, and without warranty of any kind.
Use this script at your own risk.

(c) 2025-2026 DoubleThePsycho. Licensed under the MIT License.

## RELATED LINKS

[Developer's Github:](https://github.com/DoubleThePsycho)

[Copy-WithProgress](Copy-WithProgress.md)
