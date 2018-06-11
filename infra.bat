@::!/dos/rocks
@echo off
goto :init

:header
    echo %__NAME% v%__VERSION%
    echo A simple wrapper around Docker Compose to easily manage various infrastructure 
    echo tools that I use for development.
    echo.
    goto :eof

:usage
    echo USAGE:
    echo   %__BAT_NAME% [flags] Goal [Service]
    echo.
    echo.    Ignores services:
    echo.      list         List available tools
    echo.      pull         Pull associated containers for all tools
    echo.      clean        Removes containers that are no longer running
    echo.
    echo.    Requires a service to be specified:
    echo.      start        Start a service
    echo.      stop         Stop a service
    echo.      restart      Restart a service
    echo.      status       Outputs whether a service is running or not
    echo.      tail         Tail log output from a service
    echo.
    echo.  /?, --help       shows this help
    echo.  --version        shows the version
    echo.  -v, --verbose    shows detailed output
    goto :eof

:version
    if "%~1"=="full" call :header & goto :eof
    echo %__VERSION%
    goto :eof

:missing_argument
    call :header
    call :usage
    echo.
    goto :eof

:list
    echo Available tools:
    for /R %%I in (infra\*.yml) do echo %%~nI
    goto :end

:pull
    echo "Start pulling..."
    for /R %%I in (infra\*.yml) do docker-compose -f infra\%%~nxI pull
    goto :end

:start
    echo Starting %Service%
    docker-compose -f infra\%Service%.yml up -d
    goto :end

:stop
    echo Stopping %Service%
    docker-compose -f infra\%Service%.yml down
    goto :end

:restart
    echo Restarting %Service%
    docker-compose -f infra\%Service%.yml restart
    goto :end

:status
    docker-compose -f infra\%Service%.yml ps
    goto :end

:tail
    docker-compose -f infra\%Service%.yml logs --follow
    goto :end

:clean
    for /F %%I in ('docker ps -a -q -f "status=exited"') do docker rm %%I
    goto :end

:init
    set "__NAME=%~n0"
    set "__VERSION=1.0"
    set "__YEAR=2018"

    set "__BAT_FILE=%~0"
    set "__BAT_PATH=%~dp0"
    set "__BAT_NAME=%~nx0"

    set "OptHelp="
    set "OptVersion="
    set "OptVerbose="

    set "Goal="
    set "Service="

:parse
    if "%~1"=="" goto :validate

    if /i "%~1"=="/?"         call :header & call :usage "%~2" & goto :end
    if /i "%~1"=="-?"         call :header & call :usage "%~2" & goto :end
    if /i "%~1"=="--help"     call :header & call :usage "%~2" & goto :end

    if /i "%~1"=="--version"  call :version full & goto :end

    if /i "%~1"=="-v"         set "OptVerbose=yes"  & shift & goto :parse
    if /i "%~1"=="--verbose"  set "OptVerbose=yes"  & shift & goto :parse

    if not defined Goal       set "Goal=%~1"     & shift & goto :parse
    if not defined Service    set "Service=%~1"  & shift & goto :parse

    shift
    goto :parse

:validate
    if not defined Goal call :missing_argument & goto :end

:main
    if defined OptVerbose (
        echo **** DEBUG IS ON
        echo Goal:    "%Goal%"
        if defined Service echo Service: "%Service%"
    )

    if "%Goal%"=="list" goto :list
    if "%Goal%"=="pull" goto :pull

    if "%Goal%"=="start" goto :start
    if "%Goal%"=="stop" goto :stop
    if "%Goal%"=="restart" goto :restart
    if "%Goal%"=="status" goto :status
    if "%Goal%"=="tail" goto :tail
    if "%Goal%"=="clean" goto :clean
:end
    call :cleanup
    exit /B

:cleanup
    REM The cleanup function is only really necessary if you
    REM are _not_ using SETLOCAL.
    set "__NAME="
    set "__VERSION="
    set "__YEAR="

    set "__BAT_FILE="
    set "__BAT_PATH="
    set "__BAT_NAME="

    set "OptHelp="
    set "OptVersion="
    set "OptVerbose="

    set "Goal="

    goto :eof