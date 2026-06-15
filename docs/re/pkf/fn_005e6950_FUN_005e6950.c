// FUN_005e6950  entry=005e6950  size=163 bytes

undefined4 __thiscall FUN_005e6950(int param_1,LPCSTR param_2,undefined4 param_3,undefined4 param_4)

{
  int iVar1;
  undefined1 *puVar2;
  LPSTR lpBuffer;
  
  FUN_005f99d0();
  if (param_2 != (LPCSTR)0x0) {
    FUN_005f9660(param_1 + 4,0x80,param_2);
    FUN_005f97e0(param_1 + 4);
  }
  iVar1 = FUN_005f9800(param_2,param_3,param_4,0);
  if (iVar1 != 0) {
    iVar1 = FUN_005e81c0();
    if (iVar1 != 0) {
      lpBuffer = (LPSTR)(param_1 + 0x128);
      GetFullPathNameA(param_2,0x80,lpBuffer,(LPSTR *)0x0);
      puVar2 = (undefined1 *)FUN_005e6120(lpBuffer,0,0);
      *puVar2 = 0;
      FUN_005f97e0(lpBuffer);
      return 1;
    }
  }
  FUN_005f99d0();
  return 0;
}


