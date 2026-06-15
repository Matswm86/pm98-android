// FUN_00491900  entry=00491900  size=89 bytes
// callers/callees expanded one level from seeds

void __fastcall FUN_00491900(int param_1)

{
  operator_delete(*(void **)(param_1 + 0x444));
  *(undefined4 *)(param_1 + 0x444) = 0;
  operator_delete(*(void **)(param_1 + 0x448));
  *(undefined4 *)(param_1 + 0x448) = 0;
  if (*(int **)(param_1 + 0x440) != (int *)0x0) {
    (**(code **)(**(int **)(param_1 + 0x440) + 4))(3);
  }
  *(undefined4 *)(param_1 + 0x440) = 0;
  FUN_005c5740();
  return;
}


