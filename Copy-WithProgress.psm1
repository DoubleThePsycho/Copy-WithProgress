function Copy-WithProgress
{
	# .ExternalHelp .\docs\Copy-WithProgress-help.xml

	#region PARAMETERS

	[CmdletBinding(DefaultParameterSetName = "Single")]

	param(

		#MARK: Source
		[Parameter(
			Mandatory,
			Position = 0,
			ParameterSetName = "Single"
		)]
		[System.String]
		${Source},

		#MARK: Destination
		[Parameter(
			Mandatory,
			Position = 1,
			ParameterSetName = "Single"
		)]
		[System.String]
		${Destination},

		#MARK: Source
		[Parameter(
			Position = 2,
			ParameterSetName = "Single"
		)]
		[System.String]
		${Name} = 'Single job',

		#MARK: Object
		[Parameter(
			Mandatory,
			ValueFromPipeline,
			ParameterSetName = "Multiple"
		)]
		[System.Collections.ArrayList]
		${Object},

		#MARK: ReportGap
		[Parameter()]
		[System.Int32]
		${TimeOut},

		#MARK: ReportGap
		[Parameter()]
		[System.Int32]
		${ReportGap} = 200
	)

	#endregion PARAMETERS


	#region MAIN

	#	Splatting for progress bar.
	$paramWriteProgress = @{
		Activity = 'Scanning...'
		ID       = 0
	}

	#	Display a starting initial copying progress bar.
	Write-Progress @paramWriteProgress

	#	Create empty hashtable to store common parameters.
	$CommonParams = @{}

	#	Test if Verbose mode is on, if it is, add to $CommonParams.
	if ($VerbosePreference -eq "Continue") { $CommonParams["Verbose"] = $true }

	#	Test if Debug mode is on, if it is, add to $CommonParams.
	if ($DebugPreference -eq "Continue") { $CommonParams["Debug"] = $true }

	#	Create an empty hashtable to store all the job logs.
	$JobLogs = @{}

	if ($PSCmdlet.ParameterSetName -eq 'Single')
	{
		[System.Collections.ArrayList]$Object = @()

		#	Create item for entry.
		$NewEntry = [PSCustomObject]@{
			Name        = $Name
			Source      = $Source
			Destination = $Destination
		}

		#	Add entry to list.
		$Object.Add($NewEntry) | Out-Null
	}

	#	Define regular expression that will gather number of bytes copied
	$RegexBytes = "(?<=\s+)\d+(?=\s+)"

	#region RoboCopy params

	#	MIR		= Mirror mode.
	#	NP		= Don't show progress percentage in log.
	#	NC		= Don't log file classes (existing, new file, etc.)		#	NDL		= Don't log directory names.
	#	BYTES	= Show file sizes in bytes.
	#	NJH		= Do not display RoboCopy job header (JH)
	#	NJS		= Do not display RoboCopy job summary (JS)
	#	TEE		= Display log in stdout AND i ntarget log file - We don't actually use this!
	#	L		= List items and do not copy.
	#	LOG		= Create log file.	This is how we can calculate all files and sizes.
	#	IPG		= Inter-packet gap.	Used to slow down the RoboCopy process artificially.
	$CommonRobocopyParams = '/MIR /NP /NDL /NC /BYTES /NJH /NJS'

	#endregion RoboCopy params


	#region Step 1 - Staging

	$GrandTotalFileCount = 0
	$GrandBytesTotal = 0

	for ($i = 0; $i -lt $Object.Count; $i++)
	{
		#	Verbose message.
		Write-Verbose -Message "Analyzing RoboCopy job..."

		$StagingLogPath = [System.IO.Path]::GetTempFileName()

		#	Store this Log file name in the array.
		$JobLogs[$i] = $StagingLogPath

		#	The Redirect Output Path is needed so that RoboCopy does not echo to the main screen.
		$RedirectOutputPath = [System.IO.Path]::GetTempFileName()

		$StagingArgumentList = '"{0}" "{1}" /LOG:"{2}" /L {3}' -f $Object[$i].Source, $Object[$i].Destination,
		$StagingLogPath, $CommonRobocopyParams

		#	Verbose message.
		Write-Verbose -Message ('Staging arguments: {0}' -f $StagingArgumentList)
		Start-Process -Wait -FilePath robocopy.exe -ArgumentList $StagingArgumentList -PassThru -NoNewWindow -RedirectStandardOutput $RedirectOutputPath | Out-Null

		#	Get the total number of files that will be copied.
		$StagingContent = Get-Content -Path $StagingLogPath
		$TotalFileCount = $StagingContent.Count - 1
		$BytesTotal = 0

		#	Get the total number of bytes to be copied.
		[regex]::Matches(($StagingContent -join "`n"), $RegexBytes) | ForEach-Object { $BytesTotal += $_.Value } | Out-Null

		#	Verbose message.
		Write-Verbose -Message ('Bytes to be copied for this job: {0}' -f $BytesTotal)
		Write-Verbose -Message ('Files to be copied for this job: {0}' -f $TotalFileCount)

		#	Store the grand total numbers so that we can use them later for the main progress bar.
		$GrandTotalFileCount += $TotalFileCount
		$GrandBytesTotal += $BytesTotal

		#	Splatting for progress bar.
		$paramWriteProgress = @{
			# Activity        = 'RoboCopy'
			Activity        = ('Scanning: "{0}"' -f $Object[$i].Name)
			# Status          = ("Discovered {0} files totalling {1}" -f $GrandTotalFileCount, (Convert-BytesToReadable -Value $GrandBytesTotal -Alignment 6))
			Status          = ('Discovered {0} files ({1})' -f $GrandTotalFileCount, (Convert-BytesToReadable -Value $GrandBytesTotal))
			# PercentComplete = 0
			PercentComplete = ((($i + 1) / $Object.Count) * 100)
			ID              = 0
		}

		#	Update progress bar.
		Write-Progress @paramWriteProgress

		#	Delete the unnecessary redirected output file
		Remove-Item $RedirectOutputPath @commonparams
	}

	#	Verbose message.
	Write-Verbose -Message ('Total bytes to be copied: {0}' -f $GrandBytesTotal)
	Write-Verbose -Message ('Total files to be copied: {0}' -f $GrandTotalFileCount)

	#endregion Step 1 - Staging


	#region Step 2 - Copying

	$AlreadyCopiedBytes = 0
	$AlreadyCopiedFiles = 0

	#	Splatting for progress bar.
	$paramWriteProgress = @{
		# Activity        = 'RoboCopy'
		Activity        = 'Copying files...'
		# Status          = ("Copied {0} of {1} files; Copied {2} of {3}" -f 0, $GrandTotalFileCount, (Convert-Bytes -Value 0 -Alignment 6), (Convert-Bytes -Value $GrandBytesTotal -Alignment 6))
		Status          = ("Copied {0} of {1} files; Copied {2} of {3}" -f 0, $GrandTotalFileCount, (Convert-Bytes -Value 0), (Convert-Bytes -Value $GrandBytesTotal))
		PercentComplete = 0
		ID              = 0
	}

	#	Display a starting initial copying progress bar.
	Write-Progress @paramWriteProgress

	for ($i = 0; $i -lt $Object.Count; $i++)
	{
		$RobocopyLogPath = [System.IO.Path]::GetTempFileName()

		#	The Redirect Output Path is needed so that RoboCopy does not echo to the main screen.
		$RedirectOutputPath = [System.IO.Path]::GetTempFileName()

		#	In order to do the nested progress bar, we have to get the analysis so we have something to compare with.
		$CompareLogContent = Get-Content -Path $JobLogs[$i]
		$CompareBytesCopied = 0
		$CompareFileCount = 0
		[regex]::Matches($CompareLogContent, $RegexBytes) | ForEach-Object -Process { $CompareBytesCopied += $_.Value } | Out-Null
		$CompareFileCount = $CompareLogContent.Count - 1

		#	Begin the RoboCopy process

		$ArgumentList = '"{0}" "{1}" /LOG:"{2}" {3}' -f $Object[$i].Source, $Object[$i].Destination, $RobocopyLogPath, $CommonRobocopyParams

		#	Verbose message.
		Write-Verbose -Message ("Beginning the RoboCopy process with arguments: {0}" -f $ArgumentList)

		$Robocopy = Start-Process -FilePath robocopy.exe -ArgumentList $ArgumentList -PassThru -NoNewWindow -RedirectStandardOutput $RedirectOutputPath @commonparams

		#	Start stopwatch.
		$RoboCopyStopWatch = [System.Diagnostics.Stopwatch]::StartNew()

		do
		{
			#	A Do is better than a while, because with a do, it will run all the time until the process has exited.
			#	With while, it is possible that it might miss the last part of the job, and therefor the progress will not hit 100%
			Start-Sleep -Milliseconds $ReportGap

			#	IMPORTANT: Do not remove this completely! Whenever you are doing a loop in PowerShell which is trying to
			#	determine the status of a background process, it is highly recommended to add in a wait, otherwise you
			#	risk hogging the CUP. You could reduce the value if desired to something like 10 milliseconds, but
			#	remember that this means it will check the status 100 times each second. Try to do this with -Verbose - LOL
			$BytesCopied = 0
			$LogContext = Get-Content -Path $RobocopyLogPath
			[regex]::Matches($LogContext, $RegexBytes) | ForEach-Object -Process { $BytesCopied += $_.Value } | Out-Null
			$CopiedFileCount = $LogContext.Count - 1 #	First line is always blank

			#	Verbose message.
			Write-Verbose -Message ('Total bytes copied: {0}' -f $BytesCopied)
			Write-Verbose -Message ('Total files copied: {0}' -f $CopiedFileCount)

			#	Calculate the percentage for the current job.
			$Percentage = 0
			if ($BytesCopied -gt 0) { $Percentage = ($BytesCopied / $CompareBytesCopied) * 100 }

			#	If no bytes need to be copied, set the progress to 100%.
			if ($CompareBytesCopied -eq 0) { $Percentage = 100 }

			#	Calculate the percentage for the main job.
			if (($BytesCopied + $AlreadyCopiedBytes) -gt 0) { $PercentageMain = (($BytesCopied + $AlreadyCopiedBytes) / $GrandBytesTotal) * 100 } else { $PercentageMain = 0 }

			#	If no bytes need to be copied, set the progress to 100%.
			if ($GrandBytesTotal -eq 0) { $PercentageMain = 100 }

			#	Splatting for progress bar.
			$paramWriteProgress = @{
				Activity        = 'Copying files...'
				Status          = ('Copied {0} of {1} files ({2} of {3})' -f ($CopiedFileCount + $AlreadyCopiedFiles), $GrandTotalFileCount, (Convert-Bytes -Value ($BytesCopied + $AlreadyCopiedBytes)), (Convert-Bytes -Value $GrandBytesTotal))
				PercentComplete = $PercentageMain
				ID              = 0
			}

			#	Update the main progress bar
			Write-Progress @paramWriteProgress

			#	Update the Nested progress bar, only if there is more than 1 folder
			#	If you want a different progress bar for each, use -Id $($i+1) instead of -Id 1
			if ($Object.Count -gt 1)
			{
				#	Splatting for progress bar.
				$paramWriteProgress = @{
					Activity        = ('Copying "{0}"' -f $Object[$i].Name)
					Status          = ('Copied {0} of {1} files ({2} of {3})' -f $CopiedFileCount, $CompareFileCount, (Convert-Bytes -Value $BytesCopied), (Convert-Bytes -Value $CompareBytesCopied))
					PercentComplete = $Percentage
					ID              = 1
					ParentId        = 0
				}

				#	Update the main progress bar
				Write-Progress @paramWriteProgress
			}

			if ($TimeOut -and ($RoboCopyStopWatch.Elapsed.TotalMilliseconds -ge $TimeOut))
			{
				Use-Speech ('RoboCopy is stuck on "{0}", skipping.' -f $Object[$i].Name) -Name Zira -SpeakAsync
				$Robocopy | Stop-Process
			}


		} until ($Robocopy.HasExited)

		$AlreadyCopiedBytes += $BytesCopied
		$AlreadyCopiedFiles += $CopiedFileCount

		Remove-Item $RedirectOutputPath @commonparams	#	Clean up extra log file
		Remove-Item $RobocopyLogPath @commonparams		#	Clean up Robocopy log file
		Remove-Item $JobLogs[$i] @commonparams			#	Clean up Staging log file
	}

	#	Splatting for progress bar.
	$paramWriteProgress = @{
		Activity = 'Finished.'
		Status   = 'Files copied.'
		ID       = 0
	}

	#	Update the main progress bar
	Write-Progress @paramWriteProgress

	<#
		How to remove finished progress bar?
	#>

	#endregion Step 2 - Copying


	#endregion MAIN

}