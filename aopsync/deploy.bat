cd \projects\AllOurPhotos\aopsync
call flutter build apk --release
cd build\app\outputs\flutter-apk\
del aopsync.apk*
ren app-release.apk* aopsync.apk*
scp aopsync.apk* chris@192.168.1.198:/home/chris/aop/software/client/assets
cd \projects\AllOurPhotos\aopsync
pause
