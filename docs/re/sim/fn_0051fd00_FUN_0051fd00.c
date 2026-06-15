// FUN_0051fd00  entry=0051fd00  size=39 bytes
// callers/callees expanded one level from seeds

LPSTR __thiscall FUN_0051fd00(LPSTR param_1,LPCSTR param_2)

{
  int iVar1;
  LPCSTR pCVar2;
  LPSTR pCVar3;
  
  lstrcpyA(param_1,param_2);
  pCVar2 = param_2 + 1;
  pCVar3 = param_1 + 1;
  for (iVar1 = 0x3f; iVar1 != 0; iVar1 = iVar1 + -1) {
    *(undefined4 *)pCVar3 = *(undefined4 *)pCVar2;
    pCVar2 = pCVar2 + 4;
    pCVar3 = pCVar3 + 4;
  }
  *(undefined2 *)pCVar3 = *(undefined2 *)pCVar2;
  pCVar3[2] = pCVar2[2];
  return param_1;
}


