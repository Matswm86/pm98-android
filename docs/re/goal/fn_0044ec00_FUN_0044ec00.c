// FUN_0044ec00  entry=0044ec00  size=214 bytes

void __thiscall FUN_0044ec00(int param_1,int param_2,int param_3,undefined4 param_4)

{
  int iVar1;
  
  if ((((-1 < param_2) && (param_2 < 2)) && (-1 < param_3)) &&
     (((param_3 < 0xb &&
       (param_1 = param_1 + param_2 * 0x7a0, iVar1 = param_1 + param_3 * 0xac,
       *(short *)(param_1 + 0x88 + param_3 * 0xac) != 0)) &&
      ((*(int *)(iVar1 + 0xdc) == 0 &&
       ((byte)((*(int *)(iVar1 + 0xd4) != 0) + (*(int *)(iVar1 + 0xd8) != 0)) < 2)))))) {
    *(undefined4 *)(iVar1 + 0xdc) = 1;
    *(undefined4 *)(iVar1 + 0xe8) = param_4;
    if (*(ushort *)(iVar1 + 0x88) < DAT_0066c150) {
      (**(code **)(*DAT_0066b1e0 + 0x11c))
                (*(undefined4 *)(DAT_0066c158 + (uint)*(ushort *)(iVar1 + 0x88) * 4));
      return;
    }
    (**(code **)(*DAT_0066b1e0 + 0x11c))(0);
  }
  return;
}


