// thunk_FUN_0044e5d0  entry=0044cfa0  size=5 bytes

void __fastcall thunk_FUN_0044e5d0(int *param_1)

{
  int *piVar1;
  bool bVar2;
  
  if ((param_1[1] == 0) && ((HGLOBAL)*param_1 != (HGLOBAL)0x0)) {
    if ((char)param_1[0x12] == '\0') {
      FUN_0044faf0((HGLOBAL)*param_1);
      *param_1 = 0;
    }
    *param_1 = 0;
  }
  else {
    if ((*param_1 != 0) || (param_1[0x10] != 0)) {
      FUN_0044e8b0(param_1);
    }
    FUN_0044e920((int)param_1);
    if ((DAT_0050178c < 1) || (*(int *)(DAT_00501788 + 0x18 + DAT_00501d74 * 0x134) == 0)) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    piVar1 = (int *)param_1[1];
    if (bVar2) {
      if (piVar1 != (int *)0x0) {
        (**(code **)(*piVar1 + 8))(piVar1);
      }
      param_1[1] = 0;
      piVar1 = (int *)param_1[2];
      if (piVar1 != (int *)0x0) {
        (**(code **)(*piVar1 + 8))(piVar1);
      }
      param_1[2] = 0;
      piVar1 = (int *)param_1[3];
      if (piVar1 != (int *)0x0) {
        (**(code **)(*piVar1 + 8))(piVar1);
      }
    }
    else {
      if (piVar1 == (int *)0x0) goto LAB_0044e67a;
      param_1[1] = 0;
      param_1[2] = 0;
    }
    param_1[3] = 0;
  }
LAB_0044e67a:
  *(undefined1 *)(param_1 + 0x12) = 0;
  *(undefined1 *)((int)param_1 + 0x49) = 0;
  *(undefined1 *)((int)param_1 + 0x4a) = 0;
  param_1[9] = -1;
  *(undefined1 *)((int)param_1 + 0x4b) = 0;
  return;
}


