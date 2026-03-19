# =========================================================
# CONFIGURATION SECTION
# =========================================================
$DelaySeconds        = 2
$MaxPixels           = 100

$SpeedLevel          = 100       # Range 1-inf. Does not have effect if SteppedGrowth is enabled. - DO NOT EVER SET THIS TO MORE THAN $MAXPIXELS OR THE SCRIPT WILL TAKE THE COMPUTER HOSTAGE

# GROWTH MODE TOGGLE
$EnableSteppedGrowth = $false    # Set to $true for step-instant growth (see settings below)

# STEPPED GROWTH SETTINGS
$StepDelaySeconds    = 5
$TinyBlobSize        = 800
$MediumBlobSize      = 8000
$HugeBlobSize        = 60000
# =========================================================

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class DeadPixelSimulator : Form {
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr hA, int x, int y, int cx, int cy, uint f);
    [DllImport("user32.dll")] static extern int SetWindowLong(IntPtr h, int n, int d);
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, int fsModifiers, int vlc);
    [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    [DllImport("user32.dll")] static extern bool SetSystemCursor(IntPtr hcur, uint id);
    [DllImport("user32.dll")] static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    private const uint OCR_NORMAL = 32512;
    private Timer loop = new Timer();
    private Timer stepTimer = new Timer();
    private Bitmap canvas; 
    private Bitmap cursorLookalike;
    private Random rnd = new Random();
    private Point startPoint;
    
    private bool steppedMode;
    private int currentStep = 0;
    private int[] stepTargets;
    private int speed;
    private int pixelCount = 0;
    private int maxPixels;
    private int frameCounter = 0; 
    private List<Point> infectionFrontier = new List<Point>();

    public DeadPixelSimulator(int[] targets, int stepDelay, bool isStepped, int crawlSpeed, int maxP) {
        this.stepTargets = targets;
        this.steppedMode = isStepped;
        this.speed = crawlSpeed;
        this.maxPixels = maxP;

        this.DoubleBuffered = true;
        this.BackColor = Color.Lime; 
        this.TransparencyKey = Color.Lime;
        this.FormBorderStyle = FormBorderStyle.None;
        this.Bounds = Screen.PrimaryScreen.Bounds;
        this.TopMost = true;
        this.ShowInTaskbar = false;

        CaptureSystemCursor();
        Bitmap dot = new Bitmap(1, 1);
        dot.SetPixel(0, 0, Color.Transparent);
        SetSystemCursor(dot.GetHicon(), OCR_NORMAL);

        canvas = new Bitmap(this.Width, this.Height, PixelFormat.Format32bppPArgb);
        using (Graphics g = Graphics.FromImage(canvas)) { g.Clear(Color.Transparent); }

        SetWindowLong(this.Handle, -20, GetWindowLong(this.Handle, -20) | 0x80000 | 0x20);
        RegisterHotKey(this.Handle, 1, 0x0000, 0x76); 

        startPoint = Cursor.Position;
        infectionFrontier.Add(startPoint);

        if (steppedMode) {
            RunFractalBoom(stepTargets[0]);
            stepTimer.Interval = stepDelay * 1000;
            stepTimer.Tick += (s, e) => {
                currentStep++;
                if (currentStep < stepTargets.Length) RunFractalBoom(stepTargets[currentStep]);
                else stepTimer.Stop();
            };
            stepTimer.Start();
        }

        loop.Interval = 16; 
        loop.Tick += (s, e) => {
            frameCounter++;
            
            // Recalibrated Throttling:
            // High speed = every frame. Speed 1 = every 15 frames.
            int tickGate = Math.Max(1, 16 - (speed / 7));
            
            if (!steppedMode && (frameCounter % tickGate == 0)) {
                // At low speeds, we only add a tiny amount of pixels per active tick
                int pixelsPerTick = Math.Max(1, speed / 2);
                UpdateCrawlInfection(pixelsPerTick);
            }

            SetWindowPos(this.Handle, new IntPtr(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010 | 0x0040);
            this.Invalidate();
        };
        loop.Start();
    }

    private void CaptureSystemCursor() {
        cursorLookalike = new Bitmap(32, 32, PixelFormat.Format32bppPArgb);
        using (Graphics g = Graphics.FromImage(cursorLookalike)) {
            Cursors.Arrow.Draw(g, new Rectangle(0, 0, 32, 32));
        }
    }

    private void RunFractalBoom(int targetCount) {
        UpdateCrawlInfection(targetCount - pixelCount);
    }

    private void UpdateCrawlInfection(int amountToGrow) {
        if (pixelCount >= maxPixels || amountToGrow <= 0) return;

        Rectangle rect = new Rectangle(0, 0, canvas.Width, canvas.Height);
        BitmapData data = canvas.LockBits(rect, ImageLockMode.ReadWrite, canvas.PixelFormat);
        int stride = data.Stride;
        byte[] rgbValues = new byte[Math.Abs(stride) * canvas.Height];
        Marshal.Copy(data.Scan0, rgbValues, 0, rgbValues.Length);

        int addedThisTurn = 0;
        while (addedThisTurn < amountToGrow && infectionFrontier.Count > 0 && pixelCount < maxPixels) {
            int idx = rnd.Next(infectionFrontier.Count);
            Point p = infectionFrontier[idx];

            int nx = p.X + rnd.Next(-1, 2);
            int ny = p.Y + rnd.Next(-1, 2);

            if (nx >= 0 && ny >= 0 && nx < canvas.Width && ny < canvas.Height) {
                int bIdx = (ny * stride) + (nx * 4);
                // Check Alpha channel
                if (rgbValues[bIdx + 3] == 0) {
                    rgbValues[bIdx] = 2;     // B
                    rgbValues[bIdx + 1] = 2; // G
                    rgbValues[bIdx + 2] = 2; // R
                    rgbValues[bIdx + 3] = 255; // A
                    pixelCount++;
                    addedThisTurn++;
                    infectionFrontier.Add(new Point(nx, ny));
                } else if (rnd.Next(100) > 85) {
                    infectionFrontier.RemoveAt(idx);
                }
            } else infectionFrontier.RemoveAt(idx);

            if (infectionFrontier.Count > 5000) {
                infectionFrontier.RemoveAt(rnd.Next(infectionFrontier.Count / 2));
            }
        }

        Marshal.Copy(rgbValues, 0, data.Scan0, rgbValues.Length);
        canvas.UnlockBits(data);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == 0x0312 && m.WParam.ToInt32() == 1) this.Close();
        base.WndProc(ref m);
    }

    protected override void OnPaint(PaintEventArgs e) {
        using (Bitmap buffer = new Bitmap(this.Width, this.Height)) {
            using (Graphics g = Graphics.FromImage(buffer)) {
                g.Clear(Color.Lime);
                Point m = this.PointToClient(Cursor.Position);
                if (cursorLookalike != null) g.DrawImageUnscaled(cursorLookalike, m.X, m.Y);
                g.DrawImageUnscaled(canvas, 0, 0);
            }
            e.Graphics.DrawImageUnscaled(buffer, 0, 0);
        }
    }

    protected override void OnFormClosing(FormClosingEventArgs e) {
        SystemParametersInfo(0x0057, 0, IntPtr.Zero, 0); 
        UnregisterHotKey(this.Handle, 1);
        base.OnFormClosing(e);
    }
}
"@

Start-Sleep -Seconds $DelaySeconds

if (-not ([System.Management.Automation.PSTypeName]"DeadPixelSimulator").Type) {
    $refs = @(([System.Drawing.Bitmap].Assembly.Location), ([System.Windows.Forms.Form].Assembly.Location))
    Add-Type -TypeDefinition $code -ReferencedAssemblies $refs
}

$Targets = @($TinyBlobSize, $MediumBlobSize, $HugeBlobSize)
[DeadPixelSimulator]::new($Targets, $StepDelaySeconds, $EnableSteppedGrowth, $SpeedLevel, $MaxPixels).ShowDialog()