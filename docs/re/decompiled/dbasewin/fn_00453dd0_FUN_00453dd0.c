// FUN_00453dd0  entry=00453dd0  size=56 bytes

void __thiscall FUN_00453dd0(void *this,int param_1)

{
  if (*(int *)((int)this + 8) != 0) {
    *(int *)(*(int *)((int)this + 8) + 0x50) = param_1;
    *(undefined4 *)(param_1 + 0x4c) = *(undefined4 *)((int)this + 8);
    *(int *)((int)this + 8) = param_1;
    *(undefined4 *)(param_1 + 0x50) = 0;
    return;
  }
  *(undefined4 *)(param_1 + 0x4c) = 0;
  *(int *)((int)this + 8) = param_1;
  *(int *)((int)this + 4) = param_1;
  *(undefined4 *)(param_1 + 0x50) = 0;
  return;
}


