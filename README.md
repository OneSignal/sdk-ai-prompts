# Backstage Documentation Template

This template repository contains the skeleton for adding a documentation-only
component to Backstage. This is useful for building out wikis dedicated to
specific topics, like the [OneSignal
Backstage](https://backstage.onesignal.io/docs/default/component/backstage) wiki
that tells OneSignal developers how to get new data onto the platform.

## Usage

1. Pick a name of the documentation wiki you'd like to create
1. Click the "use this template" button above and "create a new repository"
1. Create the repository with the name picked in step 1
1. Let the github actions complete to do template substitutions in your new repository
1. You can now clone the repository and start editing the docs, start by opening `docs/index.md` and review the [techdocs documentation](https://backstage.onesignal.io/docs/default/component/backstage/techdocs/) for more info on the structure of your repository
1. Follow the TODOs in your `catalog-info.yaml` file
1. Once your docs are pushed to the main branch, it may take up to 30 minutes but Backstage should pick up the new repository and begin serving the docs. You can find them by following the link in your new repository or searching for your repository name in the [docs section of backstage](https://backstage.onesignal.io/docs)


## Local "Development"

If you like to examine your documentation is rendered correctly you can run a localhost session to examine them.
Run `script/bootstrap` to install you dependencies, and start local server using `script/server`

Visit http://localhost:3000/docs/default/component/local to see how your documentation is rendered.

For more information about mkdocs syntax, see https://www.mkdocs.org/user-guide/writing-your-docs/
