// FUN_00523ed0  entry=00523ed0  size=145 bytes

void __fastcall FUN_00523ed0(int param_1)

{
  uint uVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  undefined4 local_8;
  int local_4;
  
  iVar3 = 0x62;
  uVar5 = 0x20c;
  do {
    uVar1 = *(uint *)(uVar5 + *(int *)(param_1 + 0x480));
    if ((uVar1 == 0) || (DAT_0066c150 <= uVar1)) {
      iVar4 = 0;
    }
    else {
      iVar4 = *(int *)(DAT_0066c158 + uVar1 * 4);
    }
    if (iVar4 == 0) {
      uVar2 = 0;
    }
    else {
      uVar2 = FUN_00584570(*(undefined4 *)(*(int *)(param_1 + 0x480) + 0x10));
    }
    local_8 = 0x24;
    local_4 = iVar3;
    FUN_00524500(param_1,&local_8,iVar4,uVar2);
    uVar5 = uVar5 + 4;
    iVar3 = iVar3 + 0x43;
  } while (uVar5 < 0x220);
  return;
}


