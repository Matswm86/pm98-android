// FUN_00579b80  entry=00579b80  size=225 bytes

undefined4 __thiscall FUN_00579b80(int param_1,int param_2)

{
  undefined4 uVar1;
  int iVar2;
  undefined4 uVar3;
  uint local_124;
  int local_120;
  int local_11c;
  undefined1 local_10c [256];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0061fecb;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_0058c790();
  local_4 = 0;
  uVar3 = CONCAT31((int3)((-(uint)(param_2 != 0) & 0xfffffe00) + 0x400 >> 8),0x10);
  uVar1 = FUN_0057cc40(*(undefined4 *)(param_1 + 0x10),local_10c,uVar3);
  iVar2 = FUN_0058c900(uVar1,uVar3);
  if (iVar2 == 0) {
    uVar3 = 0;
  }
  else {
    iVar2 = FUN_00579c70(param_2,&local_124);
    if (((iVar2 == 0) || (local_120 == 0)) || ((uint)(local_11c + local_120) < local_124)) {
      uVar3 = 0;
      FUN_0058c7b0();
    }
    else {
      uVar3 = 1;
      FUN_0058c7b0();
    }
  }
  local_4 = 0xffffffff;
  FUN_0058c7b0();
  ExceptionList = local_c;
  return uVar3;
}


