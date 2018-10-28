FROM microsoft/dotnet:2.1-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 3317
EXPOSE 80

FROM microsoft/dotnet:2.1-sdk AS build
WORKDIR /src
COPY ["/MvcApp2.csproj", "MvcApp2/"]
RUN dotnet restore "MvcApp2/MvcApp2.csproj"
COPY . .
WORKDIR "/src"
RUN dotnet build "MvcApp2.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "MvcApp2.csproj" -c Release -o /app

FROM base AS final