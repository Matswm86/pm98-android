// FUN_005806e0  entry=005806e0  size=46 bytes

float10 __thiscall FUN_005806e0(int param_1,int param_2)

{
  int iVar1;
  
  iVar1 = *(int *)(param_1 + 0x1e4);
  return (float10)*(float *)(iVar1 + 0x120 + param_2 * 0x20c) +
         (float10)*(float *)(iVar1 + 0x118 + param_2 * 0x20c) +
         (float10)*(float *)(iVar1 + param_2 * 0x20c + 0x11c);
}


