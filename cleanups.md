


# nsIMsgFolder::incomingServerType could be ditched?

If every folder has a server (which does seem to be the case with
folder-lookup-service), incomingServerType uses should be replaced by:

    folder->GetServer()->GetType();

or something.

Not many usages:

    $ grep -ri incomingServerType comm



