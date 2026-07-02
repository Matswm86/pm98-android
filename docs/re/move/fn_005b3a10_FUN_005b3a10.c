// FUN_005b3a10  entry=005b3a10  size=264 bytes

void __thiscall FUN_005b3a10(int param_1,int param_2,char param_3,undefined4 param_4)

{
  int iVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  int iVar5;
  int iVar6;
  int local_8;
  
  if (param_3 == '\0') {
    if (param_2 == 0) {
      local_8 = 0xc80000;
    }
    else {
      local_8 = *(int *)(param_1 + 0xe4 +
                        (*(int *)(param_2 + 0x2c4) + *(int *)(param_2 + 0x2b8) * 0xb) * 4);
    }
    iVar6 = 0;
    iVar5 = 0;
    do {
      if ((*(int **)(param_1 + 0x188))[1] <= iVar6) break;
      iVar1 = **(int **)(param_1 + 0x188) + iVar5;
      if (iVar1 == 0) {
        iVar3 = 0xc80000;
      }
      else {
        iVar3 = *(int *)(param_1 + 0xe4 +
                        (*(int *)(iVar1 + 0x2b8) * 0xb + *(int *)(iVar1 + 0x2c4)) * 4);
      }
      if ((iVar3 < local_8) &&
         (uVar2 = (uint)(short)(*(short *)(param_1 + 0xb8 +
                                          (*(int *)(iVar1 + 0x2b8) * 0xb + *(int *)(iVar1 + 0x2c4))
                                          * 2) -
                               *(short *)(param_1 + 0xb8 +
                                         (*(int *)(param_2 + 0x2c4) +
                                         *(int *)(param_2 + 0x2b8) * 0xb) * 2)),
         uVar4 = (int)uVar2 >> 0x1f, (int)((uVar2 ^ uVar4) - uVar4) < 0xe39)) {
        param_3 = '\x01';
      }
      else {
        param_3 = '\0';
      }
      iVar6 = iVar6 + 1;
      iVar5 = iVar5 + 0x3bc;
    } while (param_3 == '\0');
  }
  FUN_005aa490(param_2,param_3,param_4);
  return;
}


