// FUN_0058eca0  entry=0058eca0  size=163 bytes

void __thiscall FUN_0058eca0(int param_1,int param_2)

{
  int iVar1;
  
  if (*(int *)(param_1 + 0x40) != param_2) {
    *(int *)(param_1 + 0x40) = param_2;
    *(undefined4 *)(param_1 + 0x4c) = 0;
    if (param_2 != 0) {
      *(uint *)(*(int *)(param_1 + 0x1d4) + 0x458) =
           *(int *)(*(int *)(param_1 + 0x1d4) + 0x458) +
           (uint)(*(int *)(param_1 + 0x54) != *(int *)(param_2 + 0x2b8));
      *(undefined4 *)(param_1 + 0x54) = *(undefined4 *)(param_2 + 0x2b8);
      *(int *)(param_1 + 0x48) = param_2;
      *(int *)(param_1 + 0x44) = param_2;
      *(undefined4 *)(param_2 + 0x58) = 0;
      *(undefined4 *)(param_2 + 0x54) = 0;
      iVar1 = *(int *)(param_1 + 0x1d4);
      *(int *)(param_1 + 0x80) = *(int *)(param_1 + 0x80) + 1;
      if (((*(int *)(iVar1 + 0x448) == 0) && (*(char *)(iVar1 + 0x460) != '\0')) &&
         (*(int *)(iVar1 + 0x43c) != param_2)) {
        *(undefined1 *)(iVar1 + 0x460) = 0;
        *(undefined4 *)(*(int *)(param_1 + 0x1d4) + 0x43c) = 0;
      }
    }
  }
  return;
}


