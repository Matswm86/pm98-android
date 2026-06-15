// FUN_00598690  entry=00598690  size=172 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00598690(int param_1)

{
  int iVar1;
  int iVar2;
  
  if (*(int *)(param_1 + 0x27e8) != 0) {
    iVar1 = *(int *)(param_1 + 0x1a38);
    FUN_005c1df0(&DAT_00664f28);
    DAT_006d31c4 = 1;
    *(undefined1 *)(param_1 + 0x1a1e) = 1;
    *(undefined4 *)(param_1 + 0x27ec) = 0;
    *(undefined1 *)(param_1 + 0x180e) = 0;
    iVar2 = *(int *)(param_1 + 0x27e8);
    while ((int)((-(uint)(iVar1 != 6) & 0xffffff10) + 0x438) < iVar2) {
      FUN_00598740();
      iVar2 = *(int *)(param_1 + 0x27e8) - *(int *)(param_1 + 0x27ec);
    }
    *(undefined1 *)(param_1 + 0x1809) = 0;
    FUN_00451200();
    FUN_00593ab0();
    DAT_006d31c4 = 0;
    FUN_00594570(1);
    FUN_004511f0();
  }
  return;
}


