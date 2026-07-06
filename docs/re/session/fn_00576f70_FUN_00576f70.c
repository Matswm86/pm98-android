// FUN_00576f70  entry=00576f70  size=182 bytes

void __thiscall FUN_00576f70(undefined2 *param_1,int *param_2)

{
  undefined1 uVar1;
  int iVar2;
  int *piVar3;
  undefined1 *puVar4;
  byte *pbVar5;
  
  piVar3 = param_2;
  *param_1 = 0;
  *param_1 = *(undefined2 *)*param_2;
  iVar2 = *param_2;
  *param_2 = iVar2 + 2;
  *(undefined4 *)(param_1 + 2) = *(undefined4 *)(iVar2 + 2);
  iVar2 = *param_2;
  *param_2 = iVar2 + 4;
  *(undefined4 *)(param_1 + 4) = *(undefined4 *)(iVar2 + 4);
  iVar2 = *param_2;
  *param_2 = iVar2 + 4;
  *(undefined4 *)(param_1 + 6) = *(undefined4 *)(iVar2 + 4);
  iVar2 = *param_2;
  puVar4 = (undefined1 *)(iVar2 + 4);
  *param_2 = (int)puVar4;
  uVar1 = *puVar4;
  *param_2 = iVar2 + 5;
  *(undefined1 *)(param_1 + 0xc) = uVar1;
  uVar1 = *(undefined1 *)*param_2;
  *param_2 = (int)((undefined1 *)*param_2 + 1);
  *(undefined1 *)((int)param_1 + 0x19) = uVar1;
  pbVar5 = (byte *)*param_2;
  param_2 = (int *)(uint)*pbVar5;
  *piVar3 = (int)(pbVar5 + 1);
  *(int **)(param_1 + 8) = param_2;
  uVar1 = *(undefined1 *)*piVar3;
  *piVar3 = (int)((undefined1 *)*piVar3 + 1);
  *(undefined1 *)(param_1 + 0xd) = uVar1;
  uVar1 = *(undefined1 *)*piVar3;
  *piVar3 = (int)((undefined1 *)*piVar3 + 1);
  *(undefined1 *)((int)param_1 + 0x1b) = uVar1;
  param_1[1] = 0;
  param_1[1] = *(undefined2 *)*piVar3;
  iVar2 = *piVar3;
  pbVar5 = (byte *)(iVar2 + 2);
  *piVar3 = (int)pbVar5;
  param_2 = (int *)(uint)*pbVar5;
  *piVar3 = iVar2 + 3;
  *(int **)(param_1 + 10) = param_2;
  return;
}


