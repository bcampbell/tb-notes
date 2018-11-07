# phantom imap folder dupes

start tb
create imap account
quit
move profile to different directory
run tb with -profile pointing to new location
as it starts up, phantom folders "Sent-1", "Inbox-1" etc appear in folder pane, but then go away again.
symptom of something bonkers?

# remote javascript debugging doesn't work on xpcshell tests

Following:

    https://developer.mozilla.org/en-US/docs/Mozilla/QA/Writing_xpcshell-based_unit_tests#Debugging_xpcshell-tests

1 run xpcshell:

    $ ./mach xpcshell-test --jsdebugger comm/mailnews/base/test/unit/test_junkingWhenDisabled.js

2 run firefox (with remote debugging enabled in developer tools settings)

3 connect (to port 6000)

4 see "Main Process" listed, click it.

5 no debugging happens. In xpcshell output, see:

    0:44.70 pid:14886 [14886, Main Thread] WARNING: NS_ENSURE_TRUE(mHiddenWindow) failed: file /fast/ben/tb/mozilla/xpfe/appshell/nsAppShellService.cpp, line 783



