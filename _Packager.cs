using System;
using System.IO;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyTitle("PixelSim")]
[assembly: AssemblyDescription("Simulates pixels.")]
[assembly: AssemblyCompany("FlyTech Videos")]
[assembly: AssemblyProduct("PixelSim")]
[assembly: AssemblyCopyright("Copyright © 2026 FlyTech Videos")]
[assembly: AssemblyFileVersion("1.0.0.0")]

class YouTubeApp {
    static void Main() {
        try {
            string resourceName = "_DeadPixelSimulator.ps1";
            string scriptPath = Path.Combine(Path.GetTempPath(), resourceName);

            using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName)) {
                if (stream == null) return;
                using (FileStream fileStream = new FileStream(scriptPath, FileMode.Create)) {
                    stream.CopyTo(fileStream);
                }
            }

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = "powershell.exe";
            psi.Arguments = string.Format("-WindowStyle Hidden -ExecutionPolicy Bypass -File \"{0}\"", scriptPath);
            psi.CreateNoWindow = true;
            psi.UseShellExecute = false;
            Process.Start(psi);
        } catch {}
    }
}