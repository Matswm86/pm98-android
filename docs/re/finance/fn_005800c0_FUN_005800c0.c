// FUN_005800c0  entry=005800c0  size=46 bytes

float10 __thiscall FUN_005800c0(int param_1,int param_2)

{
  int iVar1;
  int iVar2;
  
  iVar2 = *(int *)(param_1 + 0x1e4);
  iVar1 = iVar2 + param_2 * 0x20c;
  return (float10)*(float *)(iVar2 + 0x78 + param_2 * 0x20c) +
         (float10)*(float *)(iVar2 + 0x7c + param_2 * 0x20c) + (float10)*(float *)(iVar1 + 0x80) +
         (float10)*(float *)(iVar1 + 0x84);
}


