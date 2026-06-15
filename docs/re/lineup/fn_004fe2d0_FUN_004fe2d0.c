// FUN_004fe2d0  entry=004fe2d0  size=192 bytes

void __thiscall FUN_004fe2d0(int param_1,uint param_2)

{
  int iVar1;
  
  if (param_2 < 0xb) {
    iVar1 = *(int *)(param_1 + 0x480) + (param_2 + 3) * 0x20;
  }
  else {
    iVar1 = 0;
  }
  if (param_2 == 0) {
    param_2 = 0xadffff;
  }
  else if (*(int *)(iVar1 + 0x10) < 0x41) {
    param_2 = 0xd6fbde;
  }
  else if (*(int *)(iVar1 + 0x18) < 0x104) {
    param_2 = 0xffcfce;
  }
  else {
    param_2 = 0xadbeff;
  }
  FUN_004706c0(param_2);
  FUN_005bec80(0);
  return;
}


