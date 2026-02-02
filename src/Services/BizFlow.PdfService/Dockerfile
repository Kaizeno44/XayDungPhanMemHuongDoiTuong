FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src/BizFlow.PdfService
COPY . .
RUN dotnet restore "BizFlow.PdfService.csproj"
RUN dotnet build "BizFlow.PdfService.csproj" -c Release -o /app/build

FROM build AS publish
WORKDIR /src/BizFlow.PdfService
RUN dotnet publish "BizFlow.PdfService.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "BizFlow.PdfService.dll"]
