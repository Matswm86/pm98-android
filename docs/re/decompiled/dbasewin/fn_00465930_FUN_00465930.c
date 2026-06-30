// FUN_00465930  entry=00465930  size=120 bytes

LPSTR __thiscall FUN_00465930(void *this,LPSTR param_1,int param_2)

{
  char cVar1;
  uint uVar2;
  uint uVar3;
  int iVar4;
  undefined4 *puVar5;
  char *pcVar6;
  CHAR *pCVar7;
  LPSTR pCVar8;
  CHAR local_100;
  undefined4 local_ff;
  
  uVar2 = 0xffffffff;
  pcVar6 = this;
  do {
    if (uVar2 == 0) break;
    uVar2 = uVar2 - 1;
    cVar1 = *pcVar6;
    pcVar6 = pcVar6 + 1;
  } while (cVar1 != '\0');
  uVar2 = (~uVar2 - 1) - param_2;
  local_100 = '\0';
  uVar2 = ((int)uVar2 < 1) - 1 & uVar2;
  pCVar7 = &local_100;
  for (uVar3 = uVar2 >> 2; uVar3 != 0; uVar3 = uVar3 - 1) {
    *(undefined4 *)pCVar7 = *(undefined4 *)this;
    this = (CHAR *)((int)this + 4);
    pCVar7 = pCVar7 + 4;
  }
  for (uVar3 = uVar2 & 3; uVar3 != 0; uVar3 = uVar3 - 1) {
    *pCVar7 = *(CHAR *)this;
    this = (CHAR *)((int)this + 1);
    pCVar7 = pCVar7 + 1;
  }
  (&local_100)[uVar2] = '\0';
  lstrcpyA(param_1,&local_100);
  puVar5 = &local_ff;
  pCVar8 = param_1 + 1;
  for (iVar4 = 0x3f; iVar4 != 0; iVar4 = iVar4 + -1) {
    *(undefined4 *)pCVar8 = *puVar5;
    puVar5 = puVar5 + 1;
    pCVar8 = pCVar8 + 4;
  }
  *(undefined2 *)pCVar8 = *(undefined2 *)puVar5;
  pCVar8[2] = *(CHAR *)((int)puVar5 + 2);
  return param_1;
}


