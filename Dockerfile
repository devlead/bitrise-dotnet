FROM bitriseio/docker-bitrise-base:latest

# Install .NET Core & mono & nuget
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb http://download.mono-project.com/repo/debian wheezy/snapshots/5.4.1 main" > /etc/apt/sources.list.d/mono-xamarin.list \
	&& curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list' \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 417A0893 \
    && apt-get update \
	&& apt-get install -y --no-install-recommends dotnet-sdk-2.1.300-preview1-008174 unzip mono-devel \
	&& rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && mkdir -p /opt/nuget \
    && curl -Lsfo /opt/nuget/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe

ENV PATH "$PATH:/opt/nuget"

# Prime dotnet
RUN mkdir dotnettest \
    && cd dotnettest \
    && dotnet new console -lang C# \
    && dotnet restore \
    && dotnet build \
    && dotnet run \
    && cd .. \
    && rm -r dotnettest

# Prime Integration tests & Cake
ADD integrationtestprimer integrationtestprimer
ADD cakeprimer cakeprimer
RUN cd integrationtestprimer \
    && dotnet restore hwapp.sln \
    --source "https://www.myget.org/F/xunit/api/v3/index.json" \
    --source "https://dotnet.myget.org/F/dotnet-core/api/v3/index.json" \
    --source "https://dotnet.myget.org/F/cli-deps/api/v3/index.json" \
    --source "https://api.nuget.org/v3/index.json" \
    && cd .. \
    && rm -rf integrationtestprimer \
    && cd cakeprimer \
    && dotnet restore Cake.sln \
    --source "https://www.myget.org/F/xunit/api/v3/index.json" \
    --source "https://dotnet.myget.org/F/dotnet-core/api/v3/index.json" \
    --source "https://dotnet.myget.org/F/cli-deps/api/v3/index.json" \
    --source "https://api.nuget.org/v3/index.json" \
    && cd .. \
    && rm -rf cakeprimer

# Get & Test Cake
ENV CAKE_VERSION 0.26.0
ENV CAKE_SETTINGS_SKIPVERIFICATION true
ADD cake /usr/bin/cake
RUN mkdir -p /opt/Cake/Cake \
    && curl -Lsfo Cake.zip "https://www.nuget.org/api/v2/package/Cake/$CAKE_VERSION" \
    && unzip -q Cake.zip -d "/opt/Cake/Cake" \
    && rm -f Cake.zip \
    && chmod 755 /usr/bin/cake \
    && mkdir caketest \
    && cd caketest \
    && cake --version \
    && cd .. \
    && rm -rf caketest

# Display info installed components
RUN mono --version \
    && dotnet --info \
    && mono /opt/nuget/nuget.exe help \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*