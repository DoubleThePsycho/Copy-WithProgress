function Copy-WithProgress
{
	# .ExternalHelp .\docs\Copy-WithProgress-help.xml

	#region PARAMETERS

	[CmdletBinding(DefaultParameterSetName = "Single")]
	[OutputType([System.Management.Automation.PSCustomObject])]

	param(

		#MARK: Source
		[Parameter(
			Position = 0,
			Mandatory,
			ParameterSetName = "Single"
		)]
		[System.String]
		${Source},

		#MARK: Destination
		[Parameter(
			Position = 1,
			Mandatory,
			ParameterSetName = "Single"
		)]
		[System.String]
		${Destination},

		#MARK: Name
		[Parameter(
			Position = 2,
			ParameterSetName = "Single"
		)]
		[System.String]
		${Name} = 'Single job',

		#MARK: Object
		[Parameter(
			Position = 0,
			Mandatory,
			ValueFromPipeline,
			ParameterSetName = "Multiple"
		)]
		[System.Collections.ArrayList]
		${Object},

		#MARK: NoMirror
		[Parameter()]
		[System.Management.Automation.SwitchParameter]
		${NoMirror},

		#MARK: TimeOut
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

	begin
	{
		#	Create list to hold all jobs, from -Object or the pipeline.
		$Jobs = [System.Collections.ArrayList]::new()
	}

	process
	{
		#	Collect jobs, since pipeline input arrives one item at a time.
		if ($PSCmdlet.ParameterSetName -eq 'Multiple')
		{
			foreach ($Item in $Object) { $Jobs.Add($Item) | Out-Null }
		}
	}

	end
	{
		#	Convert singular job to multiple, removing the need for further ParameterSetName checks.
		if ($PSCmdlet.ParameterSetName -eq 'Single')
		{
			#	Create PSCustomObject for entry.
			$NewEntry = [PSCustomObject]@{
				Name        = $Name
				Source      = $Source
				Destination = $Destination
			}

			#	Add entry to list.
			$Jobs.Add($NewEntry) | Out-Null
		}

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

		#	Define regular expression that will gather number of bytes copied
		$RegexBytes = "(?<=\s+)\d+(?=\s+)"

		#region RoboCopy params

		#	MIR		= Mirror mode. Copies subfolders and deletes destination files that no longer exist in the source.
		#	E		= Copies subfolders, without deleting anything. Used instead of MIR with -NoMirror.
		#	NP		= Don't show progress percentage in log.
		#	NDL		= Don't log directory names.
		#	NC		= Don't log file classes (existing, new file, etc.)
		#	BYTES	= Show file sizes in bytes.
		#	NJH		= Do not display RoboCopy job header (JH)
		#	NJS		= Do not display RoboCopy job summary (JS)
		#	L		= List items and do not copy.
		#	LOG		= Create log file.	This is how we can calculate all files and sizes.
		$CopyMode = if ($NoMirror) { '/E' } else { '/MIR' }
		$CommonRobocopyParams = '{0} /NP /NDL /NC /BYTES /NJH /NJS' -f $CopyMode

		#endregion RoboCopy params


		#region Step 1 - Staging

		$GrandTotalFileCount = 0
		$GrandBytesTotal = 0

		for ($i = 0; $i -lt $Jobs.Count; $i++)
		{
			#	Verbose message.
			Write-Verbose -Message "Analyzing RoboCopy job..."

			$StagingLogPath = [System.IO.Path]::GetTempFileName()

			#	Store this Log file name in the array.
			$JobLogs[$i] = $StagingLogPath

			#	The Redirect Output Path is needed so that RoboCopy does not echo to the main screen.
			$RedirectOutputPath = [System.IO.Path]::GetTempFileName()

			$StagingArgumentList = '"{0}" "{1}" /LOG:"{2}" /L {3}' -f $Jobs[$i].Source, $Jobs[$i].Destination, $StagingLogPath, $CommonRobocopyParams

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
				Activity        = ('Scanning: "{0}"' -f $Jobs[$i].Name)
				Status          = ('Discovered {0} files ({1})' -f $GrandTotalFileCount, (Convert-BytesToReadable -Value $GrandBytesTotal))
				PercentComplete = ((($i + 1) / $Jobs.Count) * 100)
				ID              = 0
			}

			#	Update progress bar.
			Write-Progress @paramWriteProgress

			#	Delete the unnecessary redirected output file
			Remove-Item $RedirectOutputPath @CommonParams
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
			Activity        = 'Copying files...'
			Status          = ('Copied {0} of {1} files ({2} of {3})' -f 0, $GrandTotalFileCount, (Convert-BytesToReadable -Value 0), (Convert-BytesToReadable -Value $GrandBytesTotal))
			PercentComplete = 0
			ID              = 0
		}

		#	Display a starting initial copying progress bar.
		Write-Progress @paramWriteProgress

		for ($i = 0; $i -lt $Jobs.Count; $i++)
		{
			$RobocopyLogPath = [System.IO.Path]::GetTempFileName()

			#	The Redirect Output Path is needed so that RoboCopy does not echo to the main screen.
			$RedirectOutputPath = [System.IO.Path]::GetTempFileName()

			#	In order to do the nested progress bar, we have to get the analysis so we have something to compare with.
			$CompareLogContent = Get-Content -Path $JobLogs[$i]
			$CompareBytesCopied = 0
			[regex]::Matches($CompareLogContent, $RegexBytes) | ForEach-Object -Process { $CompareBytesCopied += $_.Value } | Out-Null
			$CompareFileCount = $CompareLogContent.Count - 1

			$ArgumentList = '"{0}" "{1}" /LOG:"{2}" {3}' -f $Jobs[$i].Source, $Jobs[$i].Destination, $RobocopyLogPath, $CommonRobocopyParams

			#	Verbose message.
			Write-Verbose -Message ("Beginning the RoboCopy process with arguments: {0}" -f $ArgumentList)

			#	Start RoboCopy.
			$Robocopy = Start-Process -FilePath robocopy.exe -ArgumentList $ArgumentList -PassThru -NoNewWindow -RedirectStandardOutput $RedirectOutputPath @CommonParams

			#	Cache the process handle, otherwise ExitCode is empty once the process has exited.
			$null = $Robocopy.Handle

			#	Start stopwatch.
			$RoboCopyStopWatch = [System.Diagnostics.Stopwatch]::StartNew()
			$TimedOut = $false

			do
			{
				#	A Do is better than a while, because with a do, it will run all the time until the process has exited.
				#	With while, it is possible that it might miss the last part of the job, and therefor the progress will not hit 100%
				Start-Sleep -Milliseconds $ReportGap

				#	IMPORTANT: Do not remove this completely! Whenever you are doing a loop in PowerShell which is trying to
				#	determine the status of a background process, it is highly recommended to add in a wait, otherwise you
				#	risk hogging the CPU. You could reduce the value if desired to something like 10 milliseconds, but
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
					Status          = ('Copied {0} of {1} files ({2} of {3})' -f ($CopiedFileCount + $AlreadyCopiedFiles), $GrandTotalFileCount, (Convert-BytesToReadable -Value ($BytesCopied + $AlreadyCopiedBytes)), (Convert-BytesToReadable -Value $GrandBytesTotal))
					PercentComplete = [System.Math]::Min(100, $PercentageMain)
					ID              = 0
				}

				#	Update the main progress bar
				Write-Progress @paramWriteProgress

				#	Update the Nested progress bar, only if there is more than 1 folder
				#	If you want a different progress bar for each, use -Id $($i+1) instead of -Id 1
				if ($Jobs.Count -gt 1)
				{
					#	Splatting for progress bar.
					$paramWriteProgress = @{
						Activity        = ('Copying "{0}"' -f $Jobs[$i].Name)
						Status          = ('Copied {0} of {1} files ({2} of {3})' -f $CopiedFileCount, $CompareFileCount, (Convert-BytesToReadable -Value $BytesCopied), (Convert-BytesToReadable -Value $CompareBytesCopied))
						PercentComplete = [System.Math]::Min(100, $Percentage)
						ID              = 1
						ParentId        = 0
					}

					#	Update the nested progress bar
					Write-Progress @paramWriteProgress
				}

				#	Stop RoboCopy if it has run for longer than -TimeOut seconds.
				if ($TimeOut -and -not $TimedOut -and ($RoboCopyStopWatch.Elapsed.TotalSeconds -ge $TimeOut))
				{
					Write-Warning -Message ('RoboCopy is stuck on "{0}", skipping.' -f $Jobs[$i].Name)
					$Robocopy | Stop-Process
					$TimedOut = $true
				}

			} until ($Robocopy.HasExited)

			#	Wait for RoboCopy to fully exit and release its output file, which takes a moment after Stop-Process.
			$Robocopy.WaitForExit()
			$RoboCopyStopWatch.Stop()

			$AlreadyCopiedBytes += $BytesCopied
			$AlreadyCopiedFiles += $CopiedFileCount

			Remove-Item $RedirectOutputPath @CommonParams	#	Clean up extra log file
			Remove-Item $RobocopyLogPath @CommonParams		#	Clean up Robocopy log file
			Remove-Item $JobLogs[$i] @CommonParams			#	Clean up Staging log file

			#	RoboCopy exit codes 8 and above mean that at least one file failed to copy.
			[PSCustomObject]@{
				Name     = $Jobs[$i].Name
				Success  = (-not $TimedOut) -and ($Robocopy.ExitCode -lt 8)
				TimeSpan = $RoboCopyStopWatch.Elapsed
			}
		}

		#	Remove the progress bars.
		Write-Progress -Activity 'Copying files...' -ID 1 -ParentId 0 -Completed
		Write-Progress -Activity 'Copying files...' -ID 0 -Completed

		#endregion Step 2 - Copying
	}

	#endregion MAIN

}
