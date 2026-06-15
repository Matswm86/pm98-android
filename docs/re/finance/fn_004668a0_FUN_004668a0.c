// FUN_004668a0  entry=004668a0  size=124 bytes

undefined4 __thiscall
FUN_004668a0(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5
            ,undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  int iVar1;
  undefined4 uVar2;
  
  uVar2 = 0xffffffff;
  iVar1 = param_1;
  FUN_00436270(0xffffffff);
  iVar1 = FUN_005bc780(param_2,param_3,&DAT_00666f70,0,0,iVar1,uVar2);
  if (iVar1 == 0) {
    return 0;
  }
  *(undefined4 *)(param_1 + 0x3f4) = param_7;
  *(undefined4 *)(param_1 + 0x3f8) = param_8;
  *(undefined4 *)(param_1 + 0x3fc) = param_4;
  *(undefined4 *)(param_1 + 0x400) = param_5;
  *(undefined4 *)(param_1 + 0x404) = param_6;
  FUN_005bec80(0);
  return 1;
}


