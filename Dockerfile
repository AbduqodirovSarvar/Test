# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# Use the .NET SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["test.csproj", "."]
RUN dotnet restore "./test.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "test.csproj" -c Release -o /app/build
RUN dotnet dev-certs https

FROM build AS publish
RUN dotnet publish "test.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Use the ASP.NET runtime image for the final stage
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS final
ENV ASPNETCORE_URLS="https://*:443;http://*:80"
WORKDIR /app

# Copy the certificate from the build stage
COPY --from=build /root/.dotnet/corefx/cryptography/x509stores/my/* /root/.dotnet/corefx/cryptography/x509stores/my/

# Copy the published application
COPY --from=publish /app/publish .

ENTRYPOINT ["dotnet", "test.dll"]
