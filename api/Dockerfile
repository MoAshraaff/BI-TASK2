# Dev-mode image: runs `dotnet watch`, not a production build. api/ is
# bind-mounted over this at runtime (see docker-compose.yml), so this
# COPY + restore only warms a cache layer - the code that actually runs is
# whatever is on disk on the host, live.
FROM mcr.microsoft.com/dotnet/sdk:10.0

WORKDIR /src

# nuget.config and Packages/nuget copied before the csproj so `dotnet
# restore` can resolve BI-SDK - it is not on nuget.org, only in this repo.
COPY nuget.config .
COPY Packages/nuget ./Packages/nuget
COPY api/api.csproj ./api/
RUN dotnet restore ./api/api.csproj

COPY api ./api
WORKDIR /src/api

ENV ASPNETCORE_URLS=http://+:5228 \
    ASPNETCORE_ENVIRONMENT=Development \
    DOTNET_USE_POLLING_FILE_WATCHER=true
# Polling is required for dotnet watch to see changes written through a
# Docker Desktop bind mount on Windows - inotify events do not cross that
# boundary reliably.

EXPOSE 5228

CMD ["dotnet", "watch", "run", "--no-launch-profile", "--non-interactive"]
