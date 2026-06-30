// FUN_004658a0  entry=004658a0  size=143 bytes

LPSTR __thiscall FUN_004658a0(void *this,LPSTR param_1,uint param_2)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  undefined4 *puVar4;
  CHAR *pCVar5;
  LPSTR pCVar6;
  CHAR local_100;
  undefined4 local_ff;
  
  uVar1 = lstrlenA(this);
  local_100 = '\0';
  if ((int)param_2 < 0) {
    lstrcpyA(&local_100,(LPCSTR)((int)this + (uVar1 + param_2 & ((int)(uVar1 + param_2) < 1) - 1)));
  }
  else {
    if ((int)param_2 < (int)uVar1) {
      uVar1 = param_2;
    }
    pCVar5 = &local_100;
    for (uVar2 = uVar1 >> 2; uVar2 != 0; uVar2 = uVar2 - 1) {
      *(undefined4 *)pCVar5 = *(undefined4 *)this;
      this = (CHAR *)((int)this + 4);
      pCVar5 = pCVar5 + 4;
    }
    for (uVar2 = uVar1 & 3; uVar2 != 0; uVar2 = uVar2 - 1) {
      *pCVar5 = *(CHAR *)this;
      this = (CHAR *)((int)this + 1);
      pCVar5 = pCVar5 + 1;
    }
    (&local_100)[uVar1] = '\0';
  }
  lstrcpyA(param_1,&local_100);
  puVar4 = &local_ff;
  pCVar6 = param_1 + 1;
  for (iVar3 = 0x3f; iVar3 != 0; iVar3 = iVar3 + -1) {
    *(undefined4 *)pCVar6 = *puVar4;
    puVar4 = puVar4 + 1;
    pCVar6 = pCVar6 + 4;
  }
  *(undefined2 *)pCVar6 = *(undefined2 *)puVar4;
  pCVar6[2] = *(CHAR *)((int)puVar4 + 2);
  return param_1;
}


