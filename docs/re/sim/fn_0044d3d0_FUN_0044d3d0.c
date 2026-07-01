// FUN_0044d3d0  entry=0044d3d0  size=324 bytes

void __thiscall FUN_0044d3d0(int param_1,int param_2)

{
  int iVar1;
  undefined4 uVar2;
  int iVar3;
  int *piVar4;
  
  iVar1 = param_2 * 0x7a0 + param_1;
  FUN_00585ee0(*(undefined2 *)(param_2 * 0x7a0 + 0x7e8 + param_1));
  FUN_005793d0();
  piVar4 = (int *)(iVar1 + 0xd4);
  iVar3 = 0xb;
  do {
    if (piVar4[-3] != 0) {
      if (piVar4[0x15] != 0) {
        FUN_00584c00();
      }
      if (piVar4[0x14] != 0) {
        if (1 < (byte)((*piVar4 != 0) + (piVar4[1] != 0))) {
          if (*(ushort *)(piVar4 + -0x13) < DAT_0066c150) {
            uVar2 = *(undefined4 *)(DAT_0066c158 + (uint)*(ushort *)(piVar4 + -0x13) * 4);
          }
          else {
            uVar2 = 0;
          }
          (**(code **)(*DAT_0066b1e0 + 0x118))(uVar2);
        }
        if (piVar4[2] != 0) {
          if (*(ushort *)(piVar4 + -0x13) < DAT_0066c150) {
            uVar2 = *(undefined4 *)(DAT_0066c158 + (uint)*(ushort *)(piVar4 + -0x13) * 4);
          }
          else {
            uVar2 = 0;
          }
          (**(code **)(*DAT_0066b1e0 + 0x11c))(uVar2);
        }
      }
    }
    piVar4 = piVar4 + 0x2b;
    iVar3 = iVar3 + -1;
  } while (iVar3 != 0);
  FUN_0044e440();
  if (*(int *)(iVar1 + 0x7f0) == 0) {
    FUN_00585ee0(*(undefined2 *)(iVar1 + 0x7e8));
    FUN_005793d0();
    FUN_00578720();
  }
  FUN_0044d5f0();
  return;
}


