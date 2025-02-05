function Convert-BytesToReadable
{
	# .ExternalHelp .\docs\Convert-BytesToReadable-help.xml

	#region PARAMETERS

	[CmdletBinding()]
	[OutPutType([System.String])]
	[Alias("Convert-Bytes")]

	param(

		#MARK: Value
		[Parameter(
			Position = 0,
			ValueFromPipeline
		)]
		[System.Numerics.BigInteger]
		${Value} = 0,

		#MARK: Alignment
		[Parameter(
			Position = 1
		)]
		[System.SByte]
		${Alignment} = 0
	)

	#endregion PARAMETERS


	#region MAIN

	#	List of data sizes.
	$SiUnits = @(
		"B"			#	b is bit and B is Byte
		"KiB"		#	KiB = KibiByte
		"MiB"		#	MiB = MibiByte
		"GiB"		#	GiB = GibiByte
		"TiB"		#	TiB = TibiByte
		"PiB"		#	PiB = PibiByte
		"EiB"		#	EiB = ExbiByte
		"ZiB"		#	ZiB = ZebiByte
		"YiB"		#	YiB = YobiByte
		"RiB"		#	RiB = RobiByte
		"QiB"		#	QiB = QubiByte
	)

	$i = 0

	#	Run this loop all the while the power of 1024 and $i is less than or equal to $Value and only while $i is less than the total number of Si units.
	while (([System.Math]::Pow(1024, $i + 1) -le $Value) -and (($i + 1) -lt $SiUnits.Count)) { $i++ }

	#	Return aliugned SI notation.
	return ("{0,$($Alignment):0.##} {1}" -f [System.Double]($Value / [System.Math]::Pow(1024, $i)), $SiUnits[$i])

	#endregion MAIN

}