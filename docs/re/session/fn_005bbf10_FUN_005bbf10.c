// FUN_005bbf10  entry=005bbf10  size=164 bytes

void FUN_005bbf10(int *param_1,int param_2)

{
  HGLOBAL pvVar1;
  LPVOID pvVar2;
  int iVar3;
  undefined4 local_204;
  CHAR local_200 [512];
  
  if ((LPCVOID)*param_1 == (LPCVOID)0x0) {
    iVar3 = FUN_005bbe70(param_2);
    *param_1 = iVar3;
  }
  else {
    pvVar1 = GlobalHandle((LPCVOID)*param_1);
    if ((pvVar1 == (HGLOBAL)0x0) || (pvVar1 == (HGLOBAL)*param_1)) {
      pvVar2 = GlobalReAlloc((HGLOBAL)*param_1,param_2 + 1,0x42);
    }
    else {
      GlobalUnlock(pvVar1);
      pvVar1 = GlobalReAlloc(pvVar1,param_2 + 1,0x42);
      pvVar2 = GlobalLock(pvVar1);
    }
    *param_1 = (int)pvVar2;
    if (pvVar2 == (LPVOID)0x0) {
      local_204 = 0xffff0002;
      lstrcpyA(local_200,s_ResizeMemFun_006658c4);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
    }
  }
  return;
}


