// thunk_FUN_005cb040  entry=005c9a20  size=5 bytes
// callers/callees expanded one level from seeds

void __fastcall thunk_FUN_005cb040(int *param_1)

{
  int *piVar1;
  bool bVar2;
  
  if ((param_1[1] == 0) && (*param_1 != 0)) {
    if ((char)param_1[0x12] == '\0') {
      FUN_005bbed0(*param_1);
      *param_1 = 0;
    }
    *param_1 = 0;
  }
  else {
    if ((*param_1 != 0) || (param_1[0x10] != 0)) {
      FUN_005cb320();
    }
    FUN_005cb390();
    if ((DAT_00674804 < 1) || (*(int *)(DAT_00674800 + 0x18 + DAT_00674c2c * 0x134) == 0)) {
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
      if (piVar1 == (int *)0x0) goto LAB_005cb0ea;
      param_1[1] = 0;
      param_1[2] = 0;
    }
    param_1[3] = 0;
  }
LAB_005cb0ea:
  *(undefined1 *)(param_1 + 0x12) = 0;
  *(undefined1 *)((int)param_1 + 0x49) = 0;
  *(undefined1 *)((int)param_1 + 0x4a) = 0;
  param_1[9] = -1;
  *(undefined1 *)((int)param_1 + 0x4b) = 0;
  return;
}


