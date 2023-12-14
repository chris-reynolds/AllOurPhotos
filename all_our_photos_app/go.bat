call flutter build web --release
cd build\web
python3.11 -m http.server 80
cd ..\..