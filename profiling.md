

```
[09:11] <florian> In case this is of interest to anybody, here is a startup + shutdown profile of Thunderbird: http://bit.ly/2IrE40j
[09:49] <clokep> bcampbell: https://dpaste.de/1kww is the directions flo rian had previously given me.
[09:49] <clokep> Ugh, I don't know why that destroyed the formatting.
[09:53] <florian> bcampbell: instructions to generate a profile like this:
[09:53] <florian> MOZ_PROFILER_STARTUP_ENTRIES=5000000 MOZ_PROFILER_STARTUP=1 MOZ_PROFILER_STARTUP_FEATURES="js,stackwalk,responsiveness,mainthreadio" MOZ_PROFILER_SHUTDOWN="tb.profile" /Applications/Thunderbird\ Daily.app/Contents/MacOS/thunderbird -profile /tmp/tb-test
[09:54] <florian> then load https://deploy-preview-1522--perf-html.netlify.com/ in your browser, and drop the tb.profile file onto it
[09:54] <florian> then click the share button, and copy the tiny URL that gives you.
[09:54] <florian> then load the tiny url
[09:56] <florian> also, if you are looking to improve startup for TB users in general, doing this on a Windows machine with a mechanical hard drive will give more realistic data
[09:58] <clokep> (I'm sure we could get you one of those if necessary.)
[09:59] <florian> our (my) favorite machine to profile Firefox is https://www.amazon.com/gp/product/B07B5C855G/
[10:06] <florian> I hope in a not so distant future you'll no longer need to use a deploy preview, and will just use the normal profile.firefox.com
[10:06] <florian> err, profiler.firefox.com
[10:07] <florian> also: this step is only useful if you are using an official build (eg. a nightly build) that has its crash reporting symbols uploaded to the mozilla symbols server
[10:08] <florian> if you need help to understand the profiler UI, or get confused by what you see, don't hesitate to ask me
```

