# Build context is the repo root (not api/) so this can reach the sibling
# Packages/nuget/ folder that api.csproj's local-bi-sdk NuGet source needs.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Packages/nuget/ Packages/nuget/
COPY api/NuGet.Config api/api.csproj api/
RUN dotnet restore api/api.csproj

COPY api/ api/
RUN dotnet publish api/api.csproj -c Release -o /app/publish --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "api.dll"]
