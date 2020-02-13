# Telemetry in Thunderbird

## Docs

The Telemetry doc index is at:

https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/index.html

There's a good summary of settings (both compiletime and runtime prefs):

https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/internals/preferences.html


## Compiling

Telemetry is not compiled in by default. You need to add the following line
to your mozconfig:

    export MOZ_TELEMETRY_REPORTING=1

The nightly and release configs have this setting already (`$ grep -r MOZ_TELEMETRY_ mail/config/mozconfigs`).


## Prefs

There's a complex set of conditions to set up telemetry reporting.
The runtime settings needed for a minimal test setup are:

- `toolkit.telemetry.server` - URL where the collected data will be POSTed to
   (`https://incoming.telemetry.mozilla.org`). So if you're running a local
   server for testing, you'll likely want this to be some localhost URL.
- `toolkit.telemetry.server.owner` - The owner of the server (`Mozilla`).
   The implication is that it's polite to change this if you're running a
   non-Mozilla server.
- `toolkit.telemetry.send.overrideOfficialCheck` - usually, telemetry is only
   send for official builds (ie `export MOZILLA_OFFICIAL=1` in `mozconfig`).
   Setting this to `true` enables sending for unofficial builds.
- `datareporting.policy.dataSubmissionEnabled` - allows submission to the
   server.
- `datareporting.policy.dataSubmissionPolicyBypassNotification` - bypasses the
   checks to see if the policy has been shown and agreed to by the user. Set it
   to `true` for testing.
- `toolkit.telemetry.log.level - very handy for watching telemetry activity in
   the javascript console. `Trace`, `Debug`, `Info`, `Warn`, etc...


eg paste into your prefs.js:

```
user_pref("toolkit.telemetry.server", "http://localhost:8080/wibble");
user_pref("toolkit.telemetry.server_owner", "Nobody");
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification",true);
user_pref("datareporting.policy.dataSubmissionEnabled", true);
user_pref("toolkit.telemetry.log.level", "Trace");
user_pref("toolkit.telemetry.send.overrideOfficialCheck", true);
```

TODO: need to check the default prefs included in builds to see if there
are any telemetry-related changes required (both for testing and for release
builds).

```
pref("services.sync.telemetry.submissionInterval", 43200); // 12 hours in seconds
pref("services.sync.telemetry.maxPayloadCount", 500);
```



## Data-collection Policy

It's expected that the user will have been shown and agreed to the data
collection policy. For testing we can bypass this via
`datareporting.policy.dataSubmissionPolicyBypassNotification`
but there are a bunch of settings which track which version of the policy
the user has agreed to.

I haven't looked into the UI side here. I'd guess a bit of work needs to be
done to show/update/record policy info, using the firefox UX as a template.


## Debugging

### Running a test server

To run a test server locally to dump out the sent data, try
https://github.com/mozilla/gzipServer
(or alternatively https://github.com/bcampbell/webhole).

Make sure you set `toolkit.telemetry.server`/`toolkit.telemetry.server_owner`
to point to your local server.

### Log output

If you've got logging on (eg `user_pref("toolkit.telemetry.log.level", "Trace");`),
the output will show up on the javascript console:

    Menu => "Tools" => "Developer Tools" => "Error Console"

If data isn't showing up, keep an eye out for messages in the console.
For example: "Telemetry is not allowed to send pings" is an indication that
the official-build check is failing (overridden by
`toolkit.telemetry.send.overrideOfficialCheck`).

### Test pings

From the javascript console, you can force an immediate test ping:

    Cu.import("resource://gre/modules/TelemetrySession.jsm");
    TelemetrySession.testPing()


## Adding a telemetry probe

The types of data collection are outlined here:

https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/start/adding-a-new-probe.html#rich-data-aggregate-data

The probe definitions are contained in .yaml and .json files under `toolkit/components/telemetry` (`Scalars.yaml`, `Events.yaml` etc).
Of course, these probes are all specific to Firefox.

The definitions are set at build time, using a bunch of python scripts in
`toolkit/components/telemetry/build_scripts` to generate the C++ files which
define the probe resistry (enums, string tables etc).

The code-generation scripts look like they can handle multiple probe definition files,
so we should be able to add extra .yaml/.json files into the mix with our new probes.
But currently the build process doesn't allow for invoking the build scripts with
multiple arguments, so we'd need at least a small M-C patch to properly support extra
Thunderbird-specific probes.

We'd need a way to hook `toolkit/components/telemetry/moz.build` to slip extra
files into the `histogram_files`, `scalar_files` etc... lists. Not quite sure
what the best way to do this is.

There may be some serverside considerations - if the probe definitions are used also
by the telemetry server (I'm unsure) we need to make sure that's accounted for on the
server setup.


### Custom pings

For now, the most accessible way to add telemetry is to use a custom ping, which
doesn't require any build-time setup. See:

https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/custom-pings.html


## Other considerations

We probably need some coordination on what data is to be collected.
Perhaps a lightweight version of the
[firefox process](https://wiki.mozilla.org/Firefox/Data_Collection#Requesting_Approval)?

Do we need to worry about telemetry accidentally being sent out during
locally-run xpcshell tests? (I'd guess no. In the worst case it might
throw some rubbish at your local test server, but a default profile
won't be set up with all the policy acceptance prefs required to hit a
real live server).

Should we use a "tb-" or "mail-" prefix on TB-specific probe names to avoid
clashes?

