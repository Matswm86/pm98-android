// FUN_0058f100  entry=0058f100  size=63 bytes

void __fastcall FUN_0058f100(int param_1)

{
  int iVar1;
  
  if ((*(char *)(param_1 + 99) != '\0') && (*(int *)(*(int *)(param_1 + 0x1d4) + 0x448) == 0)) {
    iVar1 = *(int *)(param_1 + 0x40);
    *(undefined4 *)(param_1 + 0x90) = *(undefined4 *)(iVar1 + 4);
    *(undefined4 *)(param_1 + 0x94) = *(undefined4 *)(iVar1 + 8);
    *(undefined4 *)(param_1 + 0x98) = *(undefined4 *)(iVar1 + 0xc);
  }
  return;
}


