// FUN_00450db0  entry=00450db0  size=76 bytes

int __fastcall FUN_00450db0(int param_1)

{
  int iVar1;
  int *piVar2;
  int iVar3;
  
  iVar3 = *(int *)(param_1 + 0xf9c);
  iVar1 = 0;
  if (0 < iVar3) {
    piVar2 = *(int **)(param_1 + 0xf98);
    do {
      if (*piVar2 != 4) {
        if (piVar2[2] == 0) {
          if ((short)piVar2[3] == *(short *)(param_1 + 0xf88)) {
LAB_00450df1:
            iVar1 = iVar1 + 1;
          }
        }
        else if ((short)piVar2[3] == *(short *)(param_1 + 0x7e8)) goto LAB_00450df1;
      }
      piVar2 = piVar2 + 4;
      iVar3 = iVar3 + -1;
    } while (iVar3 != 0);
  }
  return iVar1;
}


