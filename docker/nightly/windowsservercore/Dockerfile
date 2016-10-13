FROM microsoft/windowsservercore
MAINTAINER brycem@microsoft.com

ARG fork=PowerShell
ARG branch=BryceM-NightlyDockerFiles
ARG Git7zip=https://github.com/git-for-windows/git/releases/download/v2.10.1.windows.1/PortableGit-2.10.1-64-bit.7z.exe
ARG GitSha256=aa0634e026c70fe8b50207b8b125a18f45e259eac32cea246e068577a6546718

ENV fork=$fork
ENV branch=$branch
ENV Git7zip=$Git7zip
ENV GitSha256=$GitSha256

COPY bootstrap.ps1 /
RUN powershell -f bootstrap.ps1 \
