// FUN_004510b0  entry=004510b0  size=189 bytes

void __thiscall
FUN_004510b0(int param_1,undefined4 param_2,int param_3,undefined4 param_4,undefined4 param_5)

{
  int iVar1;
  int *piVar2;
  undefined4 *puVar3;
  int iVar4;
  
  switch(param_2) {
  case 1:
    param_3 = param_3 + 0x2d;
    break;
  case 2:
    param_3 = param_3 + 0x5a;
    break;
  case 3:
    param_3 = param_3 + 0x69;
  }
  iVar4 = *(int *)(param_1 + 0xf9c);
  piVar2 = (int *)(param_1 + 0xf98);
  iVar1 = iVar4 + 1;
  while (iVar1 < iVar4) {
    iVar4 = *(int *)(param_1 + 0xf9c) + -1;
    *(int *)(param_1 + 0xf9c) = iVar4;
  }
  FUN_005bbf10(piVar2,iVar1 * 0x10);
  iVar4 = *(int *)(param_1 + 0xf9c);
  *(int *)(param_1 + 0xf9c) = iVar4;
  while (iVar4 < iVar1) {
    puVar3 = (undefined4 *)(*(int *)(param_1 + 0xf9c) * 0x10 + *piVar2);
    if (puVar3 != (undefined4 *)0x0) {
      *puVar3 = 0;
      puVar3[1] = 0;
      puVar3[2] = 0;
      *(undefined2 *)(puVar3 + 3) = 0;
      *(undefined2 *)((int)puVar3 + 0xe) = 0;
    }
    iVar4 = *(int *)(param_1 + 0xf9c) + 1;
    *(int *)(param_1 + 0xf9c) = iVar4;
  }
  puVar3 = (undefined4 *)(*(int *)(param_1 + 0xf9c) * 0x10 + -0x10 + *piVar2);
  *puVar3 = param_2;
  puVar3[1] = param_3;
  puVar3[2] = param_4;
  puVar3[3] = param_5;
  return;
}


