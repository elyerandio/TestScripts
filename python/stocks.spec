# -*- mode: python -*-
a = Analysis(['stocks.py'],
             pathex=['C:\\Scripts\\python'],
             hiddenimports=[],
             hookspath=None,
             runtime_hooks=None)
pyz = PYZ(a.pure)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='stocks.exe',
          debug=False,
          strip=None,
          upx=True,
          console=True )
