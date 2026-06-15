// FUN_005bbed0  entry=005bbed0  size=59 bytes
// callers/callees expanded one level from seeds

void FUN_005bbed0(HGLOBAL param_1)

{
  HGLOBAL hMem;
  
  if (param_1 != (LPCVOID)0x0) {
    hMem = GlobalHandle(param_1);
    if ((hMem != (HGLOBAL)0x0) && (hMem != param_1)) {
      GlobalUnlock(hMem);
      param_1 = hMem;
    }
    GlobalFree(param_1);
    DAT_0067462c = DAT_0067462c + -1;
  }
  return;
}


