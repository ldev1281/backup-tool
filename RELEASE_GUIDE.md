# Release Guide For Backup Tool 

A short guide on how to properly prepare and release a new version of
the [`backup-tool`](https://github.com/ldev1281/backup-tool) project.

------------------------------------------------------------------------

## Prerequisites

-   Working branch for release preparation: `dev`.
-   Version must be updated **in two places**:
    1.  `backup-tool/DEBIAN/control` --- `Version` field (Debian package
        format)
    2.  `README.md` --- displayed version
-   Git release tag: `vX.Y[.Z]` (for example, `v0.6`).

------------------------------------------------------------------------

## Pre-release checklist

1.  All changes are committed to `dev`.
2.  Version updated in `backup-tool/DEBIAN/control`.
3.  Version synchronized in `README.md`.

------------------------------------------------------------------------

## Step-by-step release process

1)  **Make changes in the project**

    -   Finish your edits and commit them to the `dev` branch.

2)  **Update version in `backup-tool/DEBIAN/control`** Open the file and
    update the `Version` field to the target package version:

    ``` debcontrol
    Version: 0.6
    ```

3)  **Update version in `README.md`**

    -   Update all version mentions (badges, installation examples,
        headers, etc.).

4)  **Create or move the tag on `dev`** Make sure you are on the `dev`
    branch:

    ``` bash
    git checkout dev
    git pull
    ```

    Assign/update the tag (replace `v0.6` with your version):

    ``` bash
    git tag -f v0.6
    ```

5)  **Push the tag with force**

    ``` bash
    git push --tags --force
    ```

> **Note:** after pushing, CI/build pipelines triggered by the tag will
> build the correct package version.
