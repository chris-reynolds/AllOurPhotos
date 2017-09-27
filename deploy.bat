set target=P:\websites\AllOurPhotos\
set sourcec=c:\projects\allourphotos\client
set sources=c:\projects\allourphotos\server
copy %sourcec%\dist\*.* %target%\client\dist
copy %sourcec%\*.htm* %target%\client\
copy %sourcec%\*.css %target%\client\
copy %sources%\*.js* %target%\server\
copy %sources%\package.json %target%\server\


