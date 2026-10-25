#!/usr/bin/env python3
"""Z-buffered flat-shaded renderer with 2x supersampling. Stdlib only."""
import struct, zlib, math

def load_stl(path):
    with open(path,'rb') as f:
        f.read(80); n=struct.unpack('<I',f.read(4))[0]; t=[]
        for _ in range(n):
            f.read(12); t.append([struct.unpack('<3f',f.read(12)) for _ in range(3)]); f.read(2)
    return t

def xform(tris, fn): return [[fn(p) for p in t] for t in tris]

LEAN=math.radians(15); S,C=math.sin(LEAN),math.cos(LEAN)
PANEL_W,PANEL_H,PANEL_T=239.0,147.0,11.0
FOOT_W=50.0
foot=load_stl('panel-stand-foot.stl')

def panel_tris():
    # Derive the seat from the slot itself rather than guessing a position.
    SLOT_FLOOR, LIP_H, FRONT_X, CLEAR = 14.0, 32.0, 30.0, 1.2
    fx_bot = FRONT_X - (LIP_H - SLOT_FLOOR) * math.tan(LEAN)
    bx, by = fx_bot + (CLEAR / 2) / C, SLOT_FLOOR      # bottom-front corner
    up=(S,C); thru=(C,-S)
    def P(u,v,z):
        return (bx + thru[0]*v + up[0]*u,
                by + thru[1]*v + up[1]*u, z)
    pv={}
    for a,u in ((0,0.0),(1,PANEL_H)):
        for b,v in ((0,0.0),(1,PANEL_T)):
            for c,z in ((0,0.0),(1,PANEL_W)): pv[(a,b,c)]=P(u,v,z)
    def q(p,r,s,t,tag): return [((pv[p],pv[r],pv[s]),tag),((pv[p],pv[s],pv[t]),tag)]
    out =q((0,0,0),(1,0,0),(1,0,1),(0,0,1),'screen')
    out+=q((0,1,0),(0,1,1),(1,1,1),(1,1,0),'case')
    out+=q((0,0,0),(0,0,1),(0,1,1),(0,1,0),'case')
    out+=q((1,0,0),(1,1,0),(1,1,1),(1,0,1),'case')
    out+=q((0,0,0),(0,1,0),(1,1,0),(1,0,0),'case')
    out+=q((0,0,1),(1,0,1),(1,1,1),(0,1,1),'case')
    return out

def ground(y=0.0, tag='floor', ext=900):
    v=[(-ext,y,-ext),(ext,y,-ext),(ext,y,ext),(-ext,y,ext)]
    return [((v[0],v[2],v[1]),tag),((v[0],v[3],v[2]),tag)]

COLOUR={'pla':(236,131,46),'pla2':(205,106,32),'screen':(22,27,38),
        'case':(70,76,90),'floor':(234,231,225)}

def look(p,yaw,pitch,dist,t):
    x,y,z=p[0]-t[0],p[1]-t[1],p[2]-t[2]
    cy,sy=math.cos(yaw),math.sin(yaw); x,z=x*cy+z*sy,-x*sy+z*cy
    cp,sp=math.cos(-pitch),math.sin(-pitch); y,z=y*cp-z*sp,y*sp+z*cp
    return (x,y,z+dist)

def render(path,scene,yaw,pitch,dist,target,W=1000,Hh=720,ortho=None,f=1100.0,ss=2):
    w,h=W*ss,Hh*ss
    bg=(248,247,244)
    fb=[list(bg)*w for _ in range(h)]
    zb=[[1e18]*w for _ in range(h)]
    L=(-0.40,0.78,-0.48); n=math.sqrt(sum(c*c for c in L)); L=tuple(c/n for c in L)
    L2=(0.55,0.25,0.6); n2=math.sqrt(sum(c*c for c in L2)); L2=tuple(c/n2 for c in L2)
    def proj(p):
        if ortho: return (w/2+p[0]*ortho*ss, h/2-p[1]*ortho*ss, p[2])
        if p[2]<=1: return None
        return (w/2+p[0]*f*ss/p[2], h/2-p[1]*f*ss/p[2], p[2])
    for tri,tag in scene:
        v=[look(p,yaw,pitch,dist,target) for p in tri]
        pr=[proj(p) for p in v]
        if any(p is None for p in pr): continue
        ux,uy,uz=(v[1][i]-v[0][i] for i in range(3))
        vx,vy,vz=(v[2][i]-v[0][i] for i in range(3))
        nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
        nl=math.sqrt(nx*nx+ny*ny+nz*nz) or 1; nx,ny,nz=nx/nl,ny/nl,nz/nl
        key=max(0.0,nx*L[0]+ny*L[1]+nz*L[2]); fill=max(0.0,nx*L2[0]+ny*L2[1]+nz*L2[2])
        shade=0.34+0.56*key+0.16*fill
        col=tuple(min(255,int(c*shade)) for c in COLOUR[tag])
        xs=[p[0] for p in pr]; ys=[p[1] for p in pr]
        x0,x1=max(0,int(min(xs))),min(w-1,int(max(xs))+1)
        y0,y1=max(0,int(min(ys))),min(h-1,int(max(ys))+1)
        (ax,ay,az),(bx,by,bz),(cx,cy,cz)=pr
        den=(by-cy)*(ax-cx)+(cx-bx)*(ay-cy)
        if abs(den)<1e-9: continue
        for py in range(y0,y1+1):
            row=fb[py]; zrow=zb[py]
            for px in range(x0,x1+1):
                w0=((by-cy)*(px-cx)+(cx-bx)*(py-cy))/den
                if w0<0: continue
                w1=((cy-ay)*(px-cx)+(ax-cx)*(py-cy))/den
                if w1<0: continue
                w2=1-w0-w1
                if w2<0: continue
                zz=w0*az+w1*bz+w2*cz
                if zz<zrow[px]:
                    zrow[px]=zz; row[px*3:px*3+3]=col
    # downsample
    out=[]
    for y in range(Hh):
        row=bytearray()
        for x in range(W):
            r=g=b=0
            for dy in range(ss):
                src=fb[y*ss+dy]
                for dx in range(ss):
                    i=(x*ss+dx)*3; r+=src[i]; g+=src[i+1]; b+=src[i+2]
            k=ss*ss; row += bytes((r//k, g//k, b//k))
        out.append(bytes(row))
    raw=b''.join(b'\x00'+r for r in out)
    def ch(t,d):
        c=struct.pack('>I',len(d))+t+d
        return c+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    open(path,'wb').write(b'\x89PNG\r\n\x1a\n'
        + ch(b'IHDR',struct.pack('>IIBBBBB',W,Hh,8,2,0,0,0))
        + ch(b'IDAT',zlib.compress(raw,9)) + ch(b'IEND',b''))
    print('wrote', path)

if __name__=='__main__':
    # 1. the printed part on its own
    one = ground() + [(t,'pla') for t in foot]
    render('01-foot.png', one, math.radians(54), math.radians(18), 330, (50,26,25), ortho=None)

    # 2. assembled, three-quarter
    asm = ground() + [(t,'pla') for z0 in (0.0,PANEL_W-FOOT_W)
                      for t in xform(foot, lambda p,z0=z0:(p[0],p[1],p[2]+z0))] + panel_tris()
    render('02-assembled.png', asm, math.radians(42), math.radians(16), 620, (PANEL_W/2,66,50))

    # 3. true side elevation - shows the 15 degree lean and the slot
    render('03-side.png', asm, 0.0, 0.0, 2000, (52,80,PANEL_W/2), ortho=3.1)
