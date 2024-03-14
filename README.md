# HTCondor Release Scripts

This directory contains scripts needed to manage the HTCondor repositories.

-   **publish-build**: This script is used to pick up a build from the BaTLab
    put the tarballs and package into the CHTC repositories. The arguments are
    as follows:
    -   area
        -   public: the CHTC public repositories
        -   private: public but non-advertise repositories (We've used the for late GSI patches in older versions of HT condor)
        -   security: password protected repositories for early access to security fixes
        -   test: Tim's testing playground
    -   version: HTCondor version
    -   build-id: HTCondor build ID
    -   repository:
        -   daily: daily builds - flows into osg-development repositories
        -   rc: CHTC release candidates
        -   update: Blessed release candidates - flows into osg-testing repositories
        -   release: final releases - flows into osg-main repositories

-   **publish-rpms**: This script is used to put third-party RPMs (e.g. pelican) into our repositories.
    -   directory: the directory containing the RPMs. This directory is expected to have sub-directories that match the platform (i.e. `x86\_64\_AlmaLinux9`)
    -   area: as above
    -   version: matching HTCondor version (to select LTS or feature repositories)
    -   repository: as above

-   **publish-debs**: This script is used to add third-party debs to the release repositories only.
    -   directory: the directory containing the debs. This directory is expected to have sub-directories that match the platform (i.e. `x86\_64\_AlmaLinux9`)
    -   area: as above
    -   version: matching HTCondor version (to select LTS or feature repositories)
    -   repository: **release** only

-   To have .debs populate into the daily, rc, and update repositories, add the packages to the proper directories on dumbo.
    -   For 23.0: `/nobackup/tim/externals/23.0`
    -   For 23.x: `/nobackup/tim/externals/23.x`
