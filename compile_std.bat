rem rgbds macro 
del %1.gb
rgbasm -o %1.o %1.asm
rgblink -o %1.gb %1.o 
rgbfix -v -p 0 %1.gb
del %1.o
taskkill /f /im bgb.exe
start bgb.exe %1.gb

