// FUN_004c44d0  entry=004c44d0  size=95 bytes

LPSTR __thiscall FUN_004c44d0(LPCSTR param_1,LPSTR param_2,LPCSTR param_3)

{
  int iVar1;
  undefined4 *puVar2;
  LPSTR pCVar3;
  CHAR local_100;
  undefined4 local_ff;
  
  lstrcpyA(&local_100,param_1);
  iVar1 = lstrlenA(&local_100);
  lstrcpyA(&local_100 + iVar1,param_3);
  lstrcpyA(param_2,&local_100);
  puVar2 = &local_ff;
  pCVar3 = param_2 + 1;
  for (iVar1 = 0x3f; iVar1 != 0; iVar1 = iVar1 + -1) {
    *(undefined4 *)pCVar3 = *puVar2;
    puVar2 = puVar2 + 1;
    pCVar3 = pCVar3 + 4;
  }
  *(undefined2 *)pCVar3 = *(undefined2 *)puVar2;
  pCVar3[2] = *(CHAR *)((int)puVar2 + 2);
  return param_2;
}


