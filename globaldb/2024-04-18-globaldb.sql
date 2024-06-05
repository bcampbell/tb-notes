-- Illustrative first-draft schema.

-- Main message table, one row per message.
-- For now, basically just a dump of the mork message table.
-- Intention is to move out all but the key fields we need for display
-- and the most common queries.
CREATE TABLE msg ( 
    id INTEGER PRIMARY KEY,   -- (alias for sqlite rowid)
    messageID TEXT NOT NULL DEFAULT '', 
    refs TEXT NOT NULL DEFAULT '',         -- REFERENCES is reserved word
    date INTEGER NOT NULL DEFAULT 0,       -- use proper datetime type?
    received INTEGER NOT NULL DEFAULT 0,   -- ditto
    subject TEXT NOT NULL DEFAULT '', 
    sender TEXT NOT NULL DEFAULT '',   -- (NOTE: FROM is reserved word)
    recipients TEXT NOT NULL DEFAULT '', 
    ccList TEXT NOT NULL DEFAULT '', 
    bccList TEXT NOT NULL DEFAULT '', 
    replyTo TEXT NOT NULL DEFAULT '', 
    flags INTEGER NOT NULL DEFAULT 0, 
    priority INTEGER NOT NULL DEFAULT 0, 
    msgSize INTEGER NOT NULL DEFAULT 0,   -- SIZE is reserved word
    storeToken TEXT NOT NULL DEFAULT '', 
    offlineMsgSize INTEGER NOT NULL DEFAULT 0, 
    numLines INTEGER NOT NULL DEFAULT 0, 
    preview TEXT NOT NULL DEFAULT '', 
    junkscore INTEGER NOT NULL DEFAULT 0, 
    junkscoreorigin TEXT NOT NULL DEFAULT '', 
    junkpercent TEXT NOT NULL DEFAULT '', 
    senderName TEXT NOT NULL DEFAULT '',   -- KILL?
    prevkeywords TEXT NOT NULL DEFAULT '', 
    keywords TEXT NOT NULL DEFAULT '', 
    remoteContentPolicy INTEGER NOT NULL DEFAULT 0, 
    protoThreadFlags INTEGER NOT NULL DEFAULT 0, 
    --  account TEXT NOT NULL DEFAULT '',     -- ACCOUNT is reserved word
    glodaId INTEGER NOT NULL DEFAULT 0, 
    xGmMsgId TEXT NOT NULL DEFAULT '', 
    xGmThrId TEXT NOT NULL DEFAULT '', 
    xGmLabels TEXT NOT NULL DEFAULT '', 
    pseudoHdr INTEGER NOT NULL DEFAULT 0,   -- KILL KILL KILL!
    enigmail INTEGER NOT NULL DEFAULT 0, 
    notAPhishMessage INTEGER NOT NULL DEFAULT 0, 
    imapUID INTEGER NOT NULL DEFAULT 0 
)

-- The folders. One row per folder.
-- For folders, everything interesting is set in folder_prop via arbitrary
-- setProperty(key, value) calls...
CREATE TABLE folder ( 
    id INTEGER PRIMARY KEY,   -- (alias for sqlite rowid)
    uri TEXT NOT NULL DEFAULT '' 
)

-- Assign messages to folder(s).
CREATE TABLE msg_folder ( 
    msg_id INTEGER NOT NULL,    -- FK to msg.id
    folder_id INTEGER NOT NULL  -- FK to folder.id
)

-- Handle arbitrary message properties (i.e. `msg.setProperty(key, value)`)
CREATE TABLE msg_prop ( 
    msg_id INTEGER NOT NULL,  -- FK to msg.id
    name TEXT NOT NULL, 
    value TEXT NOT NULL, 
    UNIQUE (msg_id, name)
)

-- Handle arbitrary folder properties (all of nsMsgFolderInfo!).
CREATE TABLE folder_prop ( 
    folder_id INTEGER NOT NULL,   -- FK to folder.id
    name TEXT NOT NULL, 
    value TEXT NOT NULL, 
    UNIQUE (folder_id, name)
)

-- Message thread structure. Not happy about this.
-- Probably break references out into own table, and have a way
-- to handle threads with missing messages (either actually missing
-- or just not delivered yet, but we know they exist because other
-- messages have as descendants.
CREATE TABLE msg_thread ( 
    msg INTEGER NOT NULL,      -- FK to msg.id
    parent INTEGER,            -- null = root
    thread INTEGER NOT NULL,   -- root msgkey
    depth INTEGER NOT NULL     -- 0=root (implies threadID==msg)
)



