// FUN_00586f10  entry=00586f10  size=87 bytes

int __thiscall FUN_00586f10(uint *param_1,int param_2,uint param_3)

{
  int iVar1;
  uint *puVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  
  puVar2 = (uint *)param_1[1];
  iVar3 = 0;
  uVar5 = 0;
  iVar4 = iVar3;
  if (*param_1 != 0) {
    do {
      if (iVar4 != 0) {
        return iVar4;
      }
      if (*puVar2 < DAT_0066c150) {
        iVar1 = *(int *)(DAT_0066c158 + *puVar2 * 4);
      }
      else {
        iVar1 = 0;
      }
      iVar3 = iVar4;
      if ((*(byte *)(iVar1 + 0x1c) == param_3) && (iVar3 = iVar1, param_2 != 0)) {
        param_2 = param_2 + -1;
        iVar3 = iVar4;
      }
      uVar5 = uVar5 + 1;
      puVar2 = puVar2 + 1;
      iVar4 = iVar3;
    } while (uVar5 < *param_1);
  }
  return iVar3;
}


