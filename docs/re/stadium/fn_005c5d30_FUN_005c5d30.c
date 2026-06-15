// FUN_005c5d30  entry=005c5d30  size=350 bytes

void __thiscall FUN_005c5d30(int param_1,undefined4 param_2,short param_3)

{
  int *piVar1;
  undefined4 *puVar2;
  short sVar3;
  int iVar4;
  int iVar5;
  void **ppvVar6;
  short sVar7;
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_006212d0;
  local_c = ExceptionList;
  ppvVar6 = &local_c;
  if (*(short *)(param_1 + 0x420) <= param_3) {
    piVar1 = (int *)(param_1 + 0x41c);
    sVar7 = param_3 + 1;
    sVar3 = *(short *)(param_1 + 0x420);
    ppvVar6 = &local_c;
    while (ExceptionList = ppvVar6, sVar7 < sVar3) {
      *(short *)(param_1 + 0x420) = sVar3 + -1;
      if (*piVar1 + (short)(sVar3 + -1) * 8 != 0) {
        FUN_005c7d50(1);
      }
      ppvVar6 = ExceptionList;
      sVar3 = *(short *)(param_1 + 0x420);
    }
    FUN_005bbf10(piVar1,(int)sVar7 << 3);
    sVar3 = *(short *)(param_1 + 0x420);
    *(short *)(param_1 + 0x420) = sVar3;
    while (ppvVar6 = ExceptionList, sVar3 < sVar7) {
      puVar2 = (undefined4 *)(*piVar1 + *(short *)(param_1 + 0x420) * 8);
      if (puVar2 != (undefined4 *)0x0) {
        *puVar2 = 0;
        *(undefined2 *)(puVar2 + 1) = 0;
      }
      *(short *)(param_1 + 0x420) = *(short *)(param_1 + 0x420) + 1;
      sVar3 = *(short *)(param_1 + 0x420);
    }
  }
  ExceptionList = ppvVar6;
  local_4 = 1;
  piVar1 = (int *)(*(int *)(param_1 + 0x41c) + param_3 * 8);
  sVar7 = *(short *)(*(int *)(param_1 + 0x41c) + 4 + param_3 * 8);
  sVar3 = sVar7 + 1;
  while (sVar3 < sVar7) {
    *(short *)(piVar1 + 1) = sVar7 + -1;
    if (*piVar1 + (short)(sVar7 + -1) * 8 != 0) {
      FUN_005c7d60(1);
    }
    sVar7 = (short)piVar1[1];
  }
  FUN_005bbf10(piVar1,(int)sVar3 << 3);
  sVar7 = (short)piVar1[1];
  *(short *)(piVar1 + 1) = sVar7;
  while (sVar7 < sVar3) {
    puVar2 = (undefined4 *)(*piVar1 + (short)piVar1[1] * 8);
    if (puVar2 != (undefined4 *)0x0) {
      *puVar2 = 0;
      puVar2[1] = 1;
    }
    *(short *)(piVar1 + 1) = (short)piVar1[1] + 1;
    sVar7 = (short)piVar1[1];
  }
  iVar5 = piVar1[1];
  iVar4 = *piVar1;
  *(undefined4 *)(iVar4 + -4 + (short)iVar5 * 8) = 1;
  *(undefined4 *)(iVar4 + -8 + (short)iVar5 * 8) = param_2;
  ExceptionList = local_c;
  return;
}


