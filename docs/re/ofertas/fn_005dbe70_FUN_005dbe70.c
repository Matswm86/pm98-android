// FUN_005dbe70  entry=005dbe70  size=135 bytes

void __thiscall
FUN_005dbe70(int param_1,int param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5)

{
  bool bVar1;
  uint uVar2;
  
  if (param_2 < 2) {
    param_2 = 1;
  }
  *(int *)(param_1 + 0x418) = param_2;
  *(undefined4 *)(param_1 + 0x41c) = param_3;
  *(undefined4 *)(param_1 + 0x420) = param_4;
  *(undefined4 *)(param_1 + 0x424) = param_5;
  FUN_005dbf00(*(undefined4 *)(param_1 + 0x428));
  bVar1 = *(int *)(param_1 + 0x41c) < *(int *)(param_1 + 0x418);
  if (bVar1) {
    uVar2 = *(uint *)(param_1 + 0xac) >> 7;
  }
  else {
    uVar2 = (uint)(byte)~(byte)(*(uint *)(param_1 + 0xac) >> 7);
  }
  if ((uVar2 & 1) != 0) {
    FUN_005bf8c0(bVar1,1);
  }
  return;
}


