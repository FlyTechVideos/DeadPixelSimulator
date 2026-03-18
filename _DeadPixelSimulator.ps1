# =========================================================
# CONFIGURATION SECTION
# =========================================================
$DelaySeconds     = 3      # Time before the impact
$DrawAllAtOnce    = $true  # TRUE: Instant crack | FALSE: Grows over time
$SpeedLevel       = 8      # 1 to 10 (Generation speed - ignored if DrawAllAtOnce is true)
$Size             = 100    # Total size of the crack
# =========================================================

$code = @"
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class DeadPixelSimulator : Form {
    [DllImport("user32.dll")] static extern IntPtr CopyIcon(IntPtr hI);
    [DllImport("user32.dll")] static extern bool SetSystemCursor(IntPtr h, uint id);
    [DllImport("user32.dll")] static extern IntPtr CreateCursor(IntPtr hI, int xL, int yL, int w, int h, byte[] aP, byte[] xP);
    [DllImport("user32.dll")] static extern bool SetWindowPos(IntPtr h, IntPtr hA, int x, int y, int cx, int cy, uint f);
    [DllImport("user32.dll")] static extern int SetWindowLong(IntPtr h, int n, int d);
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int n);

    private List<Rectangle> cracks = new List<Rectangle>();
    private Timer loop = new Timer();
    private IntPtr original;
    private Bitmap curBmp;
    private Random rnd = new Random();
    private Brush ink = new SolidBrush(Color.FromArgb(255, 1, 1, 1));
    
    private int speed;
    private int size;
    private Point lastPos;

    public DeadPixelSimulator(bool instant, int speedLevel, int size) {
        this.speed = Math.Max(1, Math.Min(10, speedLevel));
        this.size = size;
        
        this.DoubleBuffered = true;
        this.BackColor = Color.Black;
        this.TransparencyKey = Color.Black;
        this.FormBorderStyle = FormBorderStyle.None;
        this.Bounds = Screen.PrimaryScreen.Bounds;
        this.TopMost = true;
        this.ShowInTaskbar = false;

        // Capture current cursor look
        try {
            IntPtr hIcon = CopyIcon(Cursors.Arrow.Handle);
            using (Icon icon = Icon.FromHandle(hIcon)) { curBmp = icon.ToBitmap(); }
        } catch { curBmp = new Bitmap(32, 32); }

        // Hide real system cursor
        original = CopyIcon(Cursors.Arrow.Handle);
        byte[] aP = new byte[128]; for(int i=0; i<128; i++) aP[i] = 0xff;
        IntPtr blank = CreateCursor(IntPtr.Zero, 0, 0, 32, 32, aP, new byte[128]);
        SetSystemCursor(blank, 32512);

        // Layering/Click-through logic
        SetWindowLong(this.Handle, -20, GetWindowLong(this.Handle, -20) | 0x80000 | 0x20 | 0x80 | 0x08000000);

        lastPos = Cursor.Position;
        cracks.Add(new Rectangle(lastPos.X, lastPos.Y, 1, 1));

        if (instant) {
            // Generate full path immediately
            while (cracks.Count < size) { GenerateStep(10); }
        }

        loop.Interval = Math.Max(1, 50 - (speed * 4)); 
        loop.Tick += (s, e) => {
            if (!instant) GenerateStep((speed / 2) + 1);
            // Ensure window stays on top
            SetWindowPos(this.Handle, new IntPtr(-1), 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0010 | 0x0040);
            this.Invalidate();
        };
        loop.Start();
    }

    private void GenerateStep(int iterations) {
        for (int k = 0; k < iterations; k++) {
            if (cracks.Count >= size) break;

            int dir = rnd.Next(100);
            int ox = 0, oy = 0;

            // Pure "Crack" logic: stays thin, high momentum
            if (dir < 25) ox = 1;
            else if (dir < 50) ox = -1;
            else if (dir < 75) oy = 1;
            else oy = -1;

            lastPos.X += ox;
            lastPos.Y += oy;

            cracks.Add(new Rectangle(lastPos.X, lastPos.Y, 1, 1));
        }
    }

    protected override void OnPaint(PaintEventArgs e) {
        // 1. Draw Cursor FIRST (this puts it at the bottom layer)
        Point m = this.PointToClient(Cursor.Position);
        if (curBmp != null) {
            e.Graphics.DrawImage(curBmp, m.X, m.Y);
        }

        // 2. Draw Cracks SECOND (this renders them on top of the cursor)
        foreach (var r in cracks) {
            e.Graphics.FillRectangle(ink, r);
        }
    }

    protected override void OnFormClosing(FormClosingEventArgs e) {
        SetSystemCursor(original, 32512);
        base.OnFormClosing(e);
    }
}
"@

Start-Sleep -Seconds $DelaySeconds

if (-not ([System.Management.Automation.PSTypeName]"DeadPixelSimulator").Type) {
    Add-Type -TypeDefinition $code -ReferencedAssemblies "System.Windows.Forms","System.Drawing"
}

[DeadPixelSimulator]::new($DrawAllAtOnce, $SpeedLevel, $Size).ShowDialog()