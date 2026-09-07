$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class MouseShortcutsIcon {
    private static GraphicsPath Rounded(RectangleF rect, float radius) {
        var path = new GraphicsPath();
        float diameter = radius * 2;
        path.AddArc(rect.X, rect.Y, diameter, diameter, 180, 90);
        path.AddArc(rect.Right - diameter, rect.Y, diameter, diameter, 270, 90);
        path.AddArc(rect.Right - diameter, rect.Bottom - diameter, diameter, diameter, 0, 90);
        path.AddArc(rect.X, rect.Bottom - diameter, diameter, diameter, 90, 90);
        path.CloseFigure();
        return path;
    }

    private static byte[] Render(int size) {
        using (var bitmap = new Bitmap(size, size, PixelFormat.Format32bppArgb))
        using (var graphics = Graphics.FromImage(bitmap)) {
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            graphics.Clear(Color.Transparent);
            float s = size / 256f;
            using (var background = Rounded(new RectangleF(8*s, 8*s, 240*s, 240*s), 46*s))
            using (var backgroundBrush = new SolidBrush(Color.FromArgb(255, 36, 43, 48)))
                graphics.FillPath(backgroundBrush, background);

            using (var mouse = Rounded(new RectangleF(70*s, 38*s, 116*s, 178*s), 56*s))
            using (var mouseBrush = new SolidBrush(Color.FromArgb(255, 246, 248, 247)))
                graphics.FillPath(mouseBrush, mouse);

            using (var dividerPen = new Pen(Color.FromArgb(255, 36, 43, 48), Math.Max(2*s, 1)))
                graphics.DrawLine(dividerPen, 128*s, 40*s, 128*s, 104*s);

            using (var wheel = Rounded(new RectangleF(118*s, 58*s, 20*s, 42*s), 10*s))
            using (var wheelBrush = new SolidBrush(Color.FromArgb(255, 35, 163, 115)))
                graphics.FillPath(wheelBrush, wheel);

            using (var upper = Rounded(new RectangleF(63*s, 112*s, 33*s, 20*s), 8*s))
            using (var lower = Rounded(new RectangleF(63*s, 142*s, 33*s, 20*s), 8*s))
            using (var accentBrush = new SolidBrush(Color.FromArgb(255, 247, 181, 56))) {
                graphics.FillPath(accentBrush, upper);
                graphics.FillPath(accentBrush, lower);
            }

            using (var stream = new MemoryStream()) {
                bitmap.Save(stream, ImageFormat.Png);
                return stream.ToArray();
            }
        }
    }

    public static void Save(string path) {
        int[] sizes = new [] {16, 24, 32, 48, 64, 128, 256};
        var images = new List<byte[]>();
        foreach (int size in sizes) images.Add(Render(size));

        using (var file = File.Create(path))
        using (var writer = new BinaryWriter(file)) {
            writer.Write((ushort)0);
            writer.Write((ushort)1);
            writer.Write((ushort)sizes.Length);
            int offset = 6 + (16 * sizes.Length);
            for (int i = 0; i < sizes.Length; i++) {
                writer.Write((byte)(sizes[i] == 256 ? 0 : sizes[i]));
                writer.Write((byte)(sizes[i] == 256 ? 0 : sizes[i]));
                writer.Write((byte)0);
                writer.Write((byte)0);
                writer.Write((ushort)1);
                writer.Write((ushort)32);
                writer.Write((uint)images[i].Length);
                writer.Write((uint)offset);
                offset += images[i].Length;
            }
            foreach (byte[] image in images) writer.Write(image);
        }
    }
}
"@ -ReferencedAssemblies System.Drawing

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$assetDirectory = Join-Path $root "assets"
$iconPath = Join-Path $assetDirectory "MouseShortcuts.ico"
New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
[MouseShortcutsIcon]::Save($iconPath)
Write-Output $iconPath
