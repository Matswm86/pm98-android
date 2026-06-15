// FUN_0050b5f0  entry=0050b5f0  size=402 bytes

int __thiscall FUN_0050b5f0(int param_1,uint param_2,int param_3,undefined4 param_4)

{
  int iVar1;
  int iVar2;
  undefined4 uVar3;
  undefined4 uVar4;
  int iVar5;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  undefined4 extraout_ECX_02;
  int *piVar6;
  int iVar7;
  undefined1 *puVar8;
  char *pcVar9;
  undefined4 uVar10;
  undefined4 uVar11;
  undefined4 uVar12;
  
  uVar12 = 0xffffff;
  iVar2 = param_1;
  FUN_00436270(0xffffff);
  iVar2 = FUN_005c55b0(param_2,param_3,s_APPLY_FOR_LOAN_0065a380,8,0,iVar2,uVar12);
  if (iVar2 != 0) {
    *(undefined4 *)(param_1 + 0x430) = param_4;
    param_3 = 0;
    param_2 = 0x25;
    piVar6 = (int *)(param_1 + 0x1494);
    uVar12 = extraout_ECX;
    do {
      iVar7 = param_3 + 0xd2;
      uVar11 = 0xffffffff;
      iVar1 = *piVar6;
      FUN_00436270(0xffffffff);
      iVar5 = param_3 + 200;
      uVar10 = 0x200000;
      puVar8 = &DAT_00666f70;
      uVar3 = FUN_00436fb0(0x10a,0x12);
      uVar4 = FUN_00436fb0(5,param_2 - 1);
      uVar3 = FUN_00436fd0(uVar4,uVar3);
      (**(code **)(iVar1 + 0xc0))(param_1,uVar3,puVar8,uVar10,iVar5,uVar12,uVar11);
      iVar5 = FUN_0057fe80(param_3);
      piVar6[0x15] = iVar5;
      uVar12 = extraout_ECX_00;
      if (iVar5 != 0) {
        FUN_005bf8c0(0,1);
        iVar5 = piVar6[-0x418];
        uVar12 = extraout_ECX_01;
        FUN_00437020(0xff,0xdf,0);
        uVar10 = 0;
        pcVar9 = s_PAY_OFF_0065a378;
        uVar3 = FUN_00436fb0(0x55,0x10);
        uVar4 = FUN_00436fb0(0x111,param_2);
        uVar3 = FUN_00436fd0(uVar4,uVar3);
        (**(code **)(iVar5 + 0xc0))(param_1,uVar3,pcVar9,uVar10,iVar7,uVar12);
        uVar12 = extraout_ECX_02;
      }
      param_2 = param_2 + 0x14;
      param_3 = param_3 + 1;
      piVar6 = piVar6 + 0x106;
    } while (param_2 < 0x75);
  }
  return iVar2;
}


