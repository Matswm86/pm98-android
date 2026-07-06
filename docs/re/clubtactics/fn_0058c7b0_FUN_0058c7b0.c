// FUN_0058c7b0  entry=0058c7b0  size=86 bytes

void __fastcall FUN_0058c7b0(undefined4 *param_1)

{
  HLOCAL hMem;
  undefined4 uVar1;
  
  if ((*(byte *)(param_1 + 3) & 1) != 0) {
    if (param_1[4] == 0) {
      uVar1 = FUN_005ec210();
      param_1[4] = uVar1;
    }
    else {
      hMem = (HLOCAL)param_1[1];
      if (((hMem != (HLOCAL)0x0) && (hMem != (HLOCAL)0x0)) && (param_1[5] == 0)) {
        LocalFree(hMem);
        param_1[1] = 0;
        *param_1 = 0;
        param_1[2] = 0;
        param_1[3] = 0;
        param_1[5] = 0;
        return;
      }
    }
    param_1[1] = 0;
    *param_1 = 0;
    param_1[2] = 0;
    param_1[3] = 0;
    param_1[5] = 0;
  }
  return;
}


