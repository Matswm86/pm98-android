// FUN_00450e00  entry=00450e00  size=48 bytes

int __fastcall FUN_00450e00(int param_1)

{
  int iVar1;
  int *piVar2;
  int iVar3;
  
  iVar3 = *(int *)(param_1 + 0xf9c);
  iVar1 = 0;
  if (0 < iVar3) {
    piVar2 = *(int **)(param_1 + 0xf98);
    do {
      if ((*piVar2 == 4) && ((short)piVar2[3] == *(short *)(param_1 + 0x7e8))) {
        iVar1 = iVar1 + 1;
      }
      piVar2 = piVar2 + 4;
      iVar3 = iVar3 + -1;
    } while (iVar3 != 0);
  }
  return iVar1;
}


