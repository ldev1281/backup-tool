# Release Guide For Backup Tool

A short guide on how to properly prepare and release a new version of
the [`backup-tool`](https://github.com/ldev1281/backup-tool) project.

------------------------------------------------------------------------

## Prerequisites

-   Working branch for release preparation: `dev`.
-   Version must be updated **in two places**:
    1.  `backup-tool/DEBIAN/control` --- `Version` field (Debian package format)
    2.  `README.md` --- displayed version
-   Git release tag: `vX.Y[.Z]` (for example, `v0.7`).

------------------------------------------------------------------------

## Pre-release checklist

1.  Version updated in `backup-tool/DEBIAN/control`.
2.  Version updated in `README.md`.
3.  All changes are committed to `dev`.

------------------------------------------------------------------------

## Step-by-step release process

1)  **Update version in `backup-tool/DEBIAN/control`**  
    Open the file and update the `Version` field to the target package version:

    ```debcontrol
    Version: 0.7
    ```

2)  **Update version in `README.md`**

    -   Update all version mentions (badges, installation examples, headers, etc.).

3)  **Commit changes to `dev`**

    ```bash
    git checkout dev
    git pull
    git add .
    git commit -m "Release: bump version to 0.7"
    git push
    ```

4)  **Create a new tag for release**

    ```bash
    git tag v0.7
    git push --tags
    ```

    > **ℹ️ Note:**  
    > If the release already exists, but you only need to apply a small fix  
    > (like a typo in docs), you can **move the tag** instead of creating a new one:  
    >
    > ```bash
    > git tag -f v0.6
    > git push --tags --force
    > ```
    >
    > This is a workaround and should only be used for minor fixes.
    > For regular releases, always create a new tag (`v0.6.1`, `v0.7`).


> **Note:** after pushing, CI/build pipelines triggered by the tag will
> build the correct package version.
