-- Build Tears of the Kingdom: asks for your own game file and keys, then runs MacNativeGames' build in Terminal.
-- The game cannot ship as an installer: its .app is generated from your dump, so it is built here, on your Mac.
on run
	set helperName to "Build Tears of the Kingdom"
	set scriptPath to POSIX path of (path to resource "build-totk.sh")
	set outPath to "/Applications/Tears of the Kingdom.app"

	set osv to system version of (system info)
	set AppleScript's text item delimiters to "."
	set osMajor to (text item 1 of osv) as integer
	set AppleScript's text item delimiters to ""
	if osMajor < 26 then
		display dialog "MacNativeGames needs macOS 26 or later (this Mac runs " & osv & "). Update macOS, then run this again." buttons {"OK"} default button "OK" with icon stop with title helperName
		return
	end if

	display dialog "This builds Tears of the Kingdom into /Applications from your own game dump." & return & return & "You need:" & return & "- the base game 1.0.0 as .xci or .nsp" & return & "- your prod.keys" & return & "- optionally an update (1.1.2, 1.2.1 or 1.4.3) as .nsp or .nsz" & return & "- for an .nsp base game: your firmware dump folder" & return & return & "About 25 GB free (40 GB with an update), Homebrew, internet for the tools. The build runs in Terminal and takes a while." buttons {"Cancel", "Continue"} default button "Continue" with title helperName

	set gameFile to choose file with prompt "Choose your Tears of the Kingdom game file (.xci or .nsp)"
	set gamePath to POSIX path of gameFile
	set keysFile to choose file with prompt "Choose your prod.keys"
	set args to quoted form of gamePath & " -k " & quoted form of (POSIX path of keysFile)

	if gamePath ends with ".nsp" or gamePath ends with ".NSP" then
		display dialog "An .nsp base game has no system fonts inside. Choose your firmware dump folder (the .nca files, or an installed firmware's 'registered' folder)." buttons {"Cancel", "Choose folder…"} default button "Choose folder…" with title helperName
		set fwFolder to choose folder with prompt "Choose your firmware dump folder"
		set args to args & " --firmware " & quoted form of (POSIX path of fwFolder)
	end if

	set upd to display dialog "Build an update (1.1.2, 1.2.1 or 1.4.3)? Choose its .nsp or .nsz, or skip to build 1.0.0." buttons {"Cancel", "Skip (1.0.0)", "Choose update…"} default button "Choose update…" with title helperName
	if button returned of upd is "Choose update…" then
		set updFile to choose file with prompt "Choose the update (.nsp or .nsz)"
		set args to args & " --update " & quoted form of (POSIX path of updFile)
	end if

	set cmd to "clear; bash " & quoted form of scriptPath & " " & args & " -o " & quoted form of outPath & " && echo && echo 'Done: " & outPath & "' || echo 'The build stopped with an error (see above).'; echo; echo 'Press Return to close this window.'; read -r"
	tell application "Terminal"
		activate
		do script cmd
	end tell
end run
