// FUN_004f51e0  entry=004f51e0  size=126 bytes

void __fastcall FUN_004f51e0(int param_1)

{
  undefined4 uVar1;
  undefined4 extraout_ECX;
  undefined4 uVar2;
  undefined4 uVar3;
  undefined4 local_20;
  undefined4 local_1c;
  int local_18;
  int local_14;
  undefined1 local_10 [16];
  
  local_20 = 0;
  local_1c = 0;
  local_18 = *(int *)(param_1 + 0x80) - *(int *)(param_1 + 0x78);
  local_14 = *(int *)(param_1 + 0x84) - *(int *)(param_1 + 0x7c);
  FUN_0043ca50(&local_20,2,0);
  uVar3 = 0x100;
  uVar2 = extraout_ECX;
  FUN_00436270(0xffffff);
  uVar1 = FUN_00468be0(local_10,2);
  FUN_0043ce50(uVar1,uVar2,uVar3);
  return;
}


