import sys
pages = 20
objs = {1: b"<< /Type /Catalog /Pages 2 0 R >>", 3: b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"}
kids = []
n = 4
for i in range(pages):
    shade = (i % 5) / 5
    text = f"q {shade:.2f} {1-shade:.2f} 0.6 rg 0 0 612 792 re f Q BT /F1 120 Tf 150 380 Td (P{i+1}) Tj ET".encode()
    objs[n] = b"<< /Length %d >>\nstream\n" % len(text) + text + b"\nendstream"
    objs[n + 1] = b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 3 0 R >> >> /Contents %d 0 R >>" % n
    kids.append(n + 1)
    n += 2
objs[2] = b"<< /Type /Pages /Count %d /Kids [%s] >>" % (pages, b" ".join(b"%d 0 R" % k for k in kids))
out = bytearray(b"%PDF-1.4\n")
offsets = {}
for k in sorted(objs):
    offsets[k] = len(out)
    out += b"%d 0 obj\n" % k + objs[k] + b"\nendobj\n"
xref = len(out)
out += b"xref\n0 %d\n0000000000 65535 f \n" % (n)
for k in range(1, n):
    out += b"%010d 00000 n \n" % offsets[k]
out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (n, xref)
open(sys.argv[1], "wb").write(out)
