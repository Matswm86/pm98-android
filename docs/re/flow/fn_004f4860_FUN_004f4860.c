// FUN_004f4860  entry=004f4860  size=139 bytes
// callers/callees expanded one level from seeds

int __thiscall FUN_004f4860(int param_1,undefined4 param_2,int param_3,undefined4 param_4)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  undefined1 *puVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  
  if (param_3 == 0) {
    iVar3 = 0;
  }
  else {
    uVar6 = 0xffffffff;
    iVar3 = param_1;
    FUN_00436270(0);
    uVar5 = 0x800;
    puVar4 = &DAT_00666f70;
    uVar1 = FUN_00436fb0(0x8d,0x23);
    uVar2 = FUN_00436fb0(0,0xd);
    uVar1 = FUN_00436fd0(uVar2,uVar1);
    iVar3 = FUN_005bc780(param_2,uVar1,puVar4,uVar5,param_4,iVar3,uVar6);
  }
  if (iVar3 != 0) {
    FUN_005beae0(s_ProMan8_00658928);
    *(int *)(param_1 + 0x54) = param_3;
  }
  return iVar3;
}


