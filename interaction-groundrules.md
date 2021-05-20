

Notes on user interaction. BenB, [Bug 1690093](https://bugzilla.mozilla.org/show_bug.cgi?id=1690093#c23):

Actually, I had this on my list to answer. Please set flags only when really necessary, and generally only 1-2 persons. For discussions like this, just comments are fine.

    For drag/drop and normal filter transfers, there is no click happening.

Thank you for giving specific use cases and situations where this code is exercized.

When I wrote "click", I included drag&drop and keyboard and touch events. Any direct user action. The click was just an example. So, yes, drag&drop counts as interactive event, and should be triggering a dialog where necessary.

When it comes to filters, they are not a direct response to user actions, but can happen on a biff, without any relation to any user action.

    I guess what I don't understand is why would you not want to prompt for a password when doing the imap operation successfully requires it?

Thanks for asking that question explicitly. I assumed it was known to everybody, because it's a long-standing convention, but it's good to make the reasons explicit. I'll try to explain the reasons for the current decisions:

1. Thunderbird might be in the background. If you pop up a modal dialog while checking mail, Windows might make the application blink and drag the user's attention. This interrupts the user's work flow (the user might be in a video call, or watch a movie, or doing work that requires concentration), and that is detrimental to usability. Of course it's always easy to demand attention, but like parents teach their children, the timing must be right. You cannot interrupt more important things. That's why we don't want to pop up dialogs out of nowhere, without user interaction.
2. Another case is that the user is using Thunderbird, but doing something else, while the background action like biff happens. For example, the user might be typing an email, we pop up the password dialog, and the user types his email text into the password field. Ooops! Even if that doesn't happen, a dialog out of nowhere is confusing. The user wouldn't know why the dialog popped up.
3. And that can even be dangerous security wise. If we pop up legitimate password dialogs out of nowhere, and the user is supposed to enter is real password, what do you think will happen when somebody tries to phish their password with a mock password dialog? We shouldn't train our users to answer uninitated password prompts. That's why the password prompt should always be for the immediate action that the user initiated himself.
4. The same is true while the user is creating a calendar event, or reading email from a different mail account. If a password prompt pops up, the user is in a different frame of mind and thinks of the account that he's reading right now, not the account that the biff is happening for and the password prompt is for. Sure, the password prompt does mention the account, but we all know that users don't read. The user thinks of the account he's reading, so he enters that password, so he ends up sending his Gmail password to Yahoo. Ooops. That is our fault, because the prompt came out of context.

I hope that shows the rationale why we explicitly do not want password prompts or any prompts whatsoever pop up, unless they are about the immediate action that the user himself initiated right there.

Often, the very same action can be triggered either by the user or by a background task - e.g. a message move can be drag&drop (interactive) or a incoming mail filter (background). So, the way to reflect that - in the TB architecture - is to pass in the window reference to the function (or no window for background tasks, respectively), and then the IMAP code can know whether it should pop up a dialog or not.

Also, by passing the window reference, the code then knows the right window to show the prompt in. The top most window is often right, but not always, and when it's not, it's a bug.

This is how this code is designed: No window reference means background task, and don't throw up dialogs. Having a msgWindow means that the user initiated the action, and you can show prompts where absolutely necessary, and you have a window to root the dialogs on. (If there is code that does something else, that is a bug in that code.)

