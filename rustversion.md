Found rustc crashing on me:
https://github.com/rust-lang/rust/issues/45439 

Switching to nightly rustc helped for a while. Until it didn't.

Switch to nightly rustc and rebuild:

    $ rustup default nightly
    $ ./mach configure
    $ ./mach build

See which rustc is default:

    $ rustup show

