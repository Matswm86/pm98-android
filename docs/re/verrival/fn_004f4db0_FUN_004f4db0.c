// FUN_004f4db0  entry=004f4db0  size=122 bytes

int FUN_004f4db0(undefined4 param_1,undefined4 param_2)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  undefined1 *puVar4;
  undefined4 uVar5;
  undefined4 extraout_var;
  undefined4 uVar6;
  undefined4 uVar7;
  
  uVar7 = 0xffffffff;
  FUN_00436270(0);
  uVar5 = 0x800;
  puVar4 = &DAT_00666f70;
  uVar6 = extraout_var;
  uVar1 = FUN_00436fb0(0x8d,0x28);
  uVar2 = FUN_00436fb0(0,10);
  uVar1 = FUN_00436fd0(uVar2,uVar1);
  iVar3 = FUN_005bc780(param_1,uVar1,puVar4,uVar5,param_2,uVar6,uVar7);
  if (iVar3 != 0) {
    FUN_005beae0(s_ProMan8_00658928);
  }
  return iVar3;
}


