// Function to dump some text out to a local file (in /tmp)
// TODO: use IOUtils instead!!!
//
// https://firefox-source-docs.mozilla.org/dom/ioutils_migration.html

const { OS } = ChromeUtils.import("resource://gre/modules/osfile.jsm");

async function dumpFile(filename, txt) {
  let path = OS.Path.join(OS.Constants.Path.tmpDir, filename);
  let bytes = new Uint8Array(new TextEncoder().encode(txt));
  let f = await OS.File.open(path, {write: true, trunc: true});
  await f.write(bytes);
  await f.close();
}


