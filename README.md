# Dead Pixel Simulator

Because who doesn't love a dead pixel on the screen ...

![Dead pixel simulator showcase](showcase.png)

As seen on YouTube (link to be updated once the video is online).

## Why is this a weird repo and not just a downloadable .EXE?

I made the experience with [BlueScreenSimulator](https://github.com/FlyTechVideos/BluescreenSimulator) that AVs were overly eager to mark it as "JokeWare" which led to loads of false detections. While I understand the reasons behind it (after all, certainly not a professional software), it did cause many people to be concerned about it.

This time, I provide you with the scripts to self compile.

## How to run:

Basically all you have to do is this:

1. Clone the repo / download as ZIP
2. Unzip (if zipped) and open a PowerShell inside
3. Run this code

```powershell
Set-ExecutionPolicy RemoteSigned –Scope Process
.\Compiler.ps1
```

4. An exe file named "simulacron.exe" will spawn.
5. Enjoy.

## What can I change?

### Configurations regarding the dead pixels

You can change some stuff regarding the dead pixel generation. The constants are at the top of [_DeadPixelSimulator.ps1](./DeadPixelSimulator.ps1). They should be fairly self explanatory.

Should you desire different patterns, more configs etc. please consult the clanker programmer of your choice. (No shame.)

### Configurations regarding the generated EXE

- Want to change the data in properties? Open [_Packager.cs](./_Packager.cs) and adapt the values on the top of the file.
- Want to change the icon? The script literally just takes **DeadPixel.ico**. Replace that with whatever you want and run the compiler script again. Note: Must be a valid .ico file. Just renaming a .png to .ico will not work.# Dead Pixel Simulator

... as seen on YouTube (link to be updated once the video is online).

## Why is this a weird repo and not just a downloadable .EXE?

I made the experience with [BlueScreenSimulator](https://github.com/FlyTechVideos/BluescreenSimulator) that AVs were overly eager to mark it as "JokeWare" which led to loads of false detections. While I understand the reasons behind it (after all, certainly not a professional software), it did cause many people to be concerned about it.

This time, I provide you with the scripts to self compile. Basically all you have to do is this:

1. Clone the repo / download as ZIP
2. Unzip (if zipped) and open a PowerShell inside
3. Run this code

```powershell
Set-ExecutionPolicy RemoteSigned –Scope Process
.\Compiler.ps1
```

4. An exe file named "simulacron.exe" will spawn.
5. Enjoy.

## What can I change?

### Configurations regarding the dead pixels

You can change some stuff regarding the dead pixel generation. The constants are at the top of [_DeadPixelSimulator.ps1](./DeadPixelSimulator.ps1). They should be fairly self explanatory.

Should you desire different patterns, more configs etc. please consult the clanker programmer of your choice. (No shame.)

### Configurations regarding the generated EXE

- Want to change the data in properties? Open [_Packager.cs](./_Packager.cs) and adapt the values on the top of the file.
- Want to change the icon? The script literally just takes **DeadPixel.ico**. Replace that with whatever you want and run the compiler script again. Note: Must be a valid .ico file. Just renaming a .png to .ico will not work.
- Want to change the generated filename? You can either change the name in Compiler.ps1 or ... hear me out ... just rename the output file. 