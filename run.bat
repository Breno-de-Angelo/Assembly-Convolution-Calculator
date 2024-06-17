@echo off

set filename=%1

rescan
if errorlevel 1 goto error

call nasm %filename%
if errorlevel 1 goto error

freelink %filename% > NUL
if errorlevel 1 goto error

%filename%.exe

goto sucess

:error
    echo Deu errado.
    goto end

:sucess
    echo Tudo certo.
    goto end

:end