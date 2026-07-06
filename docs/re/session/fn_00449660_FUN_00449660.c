// FUN_00449660  entry=00449660  size=87 bytes

void __thiscall FUN_00449660(int param_1,undefined4 *param_2,int param_3)

{
  undefined4 *puVar1;
  
  if ((-1 < param_3) && (param_3 < (int)(uint)*(ushort *)(param_1 + 100))) {
    puVar1 = (undefined4 *)(param_3 * 0x10 + *(int *)(param_1 + 0x60));
    *param_2 = *puVar1;
    param_2[1] = puVar1[1];
    param_2[2] = puVar1[2];
    param_2[3] = puVar1[3];
    return;
  }
  *(undefined2 *)param_2 = 0;
  *(undefined2 *)((int)param_2 + 2) = 0;
  param_2[1] = 0;
  *(undefined1 *)(param_2 + 2) = 0;
  param_2[3] = 0;
  return;
}


