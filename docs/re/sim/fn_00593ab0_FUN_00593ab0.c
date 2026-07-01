// FUN_00593ab0  entry=00593ab0  size=184 bytes

void __fastcall FUN_00593ab0(int param_1)

{
  char cVar1;
  int iVar2;
  bool bVar3;
  
  bVar3 = *(char *)(param_1 + 0x3ec) == '\0';
  if (bVar3) {
    FUN_00594310();
  }
  *(undefined1 *)(param_1 + 0x180e) = 1;
  *(undefined4 *)(param_1 + 0x1990) = 0;
  *(undefined4 *)(param_1 + 0x198c) = 6000;
  FUN_00598740();
  *(undefined4 *)(param_1 + 0x1a3c) = 0;
  iVar2 = FUN_005bce40(0);
  if (iVar2 == -1) {
    iVar2 = 10;
  }
  *(int *)(param_1 + 0x1a3c) = iVar2;
  if (bVar3) {
    FUN_00594380();
  }
  if (*(int *)(param_1 + 0x1a3c) != 10) {
    if ((DAT_006d31c4 != '\0') || (*(int *)(param_1 + 0x1a3c) != 0)) {
      cVar1 = FUN_00598740();
      while (cVar1 != '\0') {
        cVar1 = FUN_00598740();
      }
      if (*(int *)(param_1 + 0x1a38) != 0) {
        *(undefined1 *)(param_1 + 0x1a1e) = 1;
      }
    }
    return;
  }
  *(undefined4 *)(param_1 + 0x1a38) = 10;
  return;
}


