FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy the .csproj files and restore dependencies
COPY src/Services/BizFlow.OrderAPI/BizFlow.OrderAPI.csproj ./src/Services/BizFlow.OrderAPI/
COPY src/BuildingBlocks/Shared.Kernel/Shared.Kernel.csproj ./src/BuildingBlocks/Shared.Kernel/
WORKDIR /src/Services/BizFlow.OrderAPI
RUN dotnet restore BizFlow.OrderAPI.csproj

# Copy the remaining source code and build
COPY . .
RUN dotnet publish -c Release -o out

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/out .
ENTRYPOINT ["dotnet", "BizFlow.OrderAPI.dll"]
