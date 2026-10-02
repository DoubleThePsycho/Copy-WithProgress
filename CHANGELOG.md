# Changelog

All notable changes to Copy-WithProgress are listed here. Each version is tagged in git (`v1.0.0`, `v1.1.0`, ...).

The module was developed without version control until 1.2.0, so the entries for 1.0.0 and 1.1.0 were rebuilt from
the saved copy of each version and the original notes.

## 1.2.0 - 2026-10-02

### Added

- When done, one object is returned per job, with the job's `Name`, `Success` and how long it took (`TimeSpan`).
  `Success` is `$false` when the job timed out, or when Robocopy returned exit code 8 or higher.
- `-NoMirror` copies with `/E` instead of `/MIR`, so files that only exist in the destination are kept.

### Changed

- `-TimeOut` is in seconds instead of milliseconds.
- A job that times out writes a warning instead of using text-to-speech, which needed a function from outside the
  module.

### Fixed

- Piping several jobs to `Copy-WithProgress` only copied the last one.
- The progress bars are removed when copying is done.
- `Convert-BytesToReadable` rounded down to whole numbers, so 1536 bytes showed as `1 KiB` instead of `1.5 KiB`.
- Stopping a job that timed out could fail to clean up Robocopy's temporary output file.
- The help documented `-Name` as mandatory and `-ReportGap` as slowing down the copy. `-Name` is optional and
  `-ReportGap` sets how often the progress bar updates.

## 1.1.0 - 2025-03-02

### Added

- `-TimeOut` sets how many milliseconds to try copying before giving up.

  An issue was discovered using `Copy-WithProgress` in my scheduled `PSDeepFreezeUtils` project. Attempting to copy
  the files for an actively running application would in some cases freeze, presumably because content was
  constantly being written to said files, so Robocopy would get stuck.

  > This issue was discovered by me running a specific program for a week straight, not noticing my machine slowing
  > down. Finally closing the application, I was bombarded with synthesized speech messages, as well as noticing the
  > speed increase.

- `-Name` sets the name shown in the progress bar when copying a single folder.

## 1.0.0 - 2025-02-05

The Copy-WithProgress module is created.

### Added

- `Copy-WithProgress` copies one or several folders with Robocopy, showing the progress as a progress bar, with a
  nested progress bar per folder when copying several.
- `Convert-BytesToReadable`, with the alias `Convert-Bytes`, formats a number of bytes with binary units.
