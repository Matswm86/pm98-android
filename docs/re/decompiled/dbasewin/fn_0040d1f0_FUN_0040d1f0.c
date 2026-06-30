// FUN_0040d1f0  entry=0040d1f0  size=39 bytes

LPSTR __thiscall FUN_0040d1f0(void *this,LPCSTR param_1)

{
  int iVar1;
  LPCSTR pCVar2;
  undefined4 *puVar3;
  
  lstrcpyA(this,param_1);
  pCVar2 = param_1 + 1;
  puVar3 = (undefined4 *)((int)this + 1);
  for (iVar1 = 0x3f; iVar1 != 0; iVar1 = iVar1 + -1) {
    *puVar3 = *(undefined4 *)pCVar2;
    pCVar2 = pCVar2 + 4;
    puVar3 = puVar3 + 1;
  }
  *(undefined2 *)puVar3 = *(undefined2 *)pCVar2;
  *(CHAR *)((int)puVar3 + 2) = pCVar2[2];
  return this;
}


