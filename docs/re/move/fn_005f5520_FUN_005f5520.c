// FUN_005f5520  entry=005f5520  size=34 bytes

bool __thiscall FUN_005f5520(int *param_1,int param_2,undefined2 param_3)

{
  param_1[param_2 + 8] = 1;
  *(undefined2 *)((int)param_1 + param_2 * 2 + 0x10) = param_3;
  return *param_1 == 0;
}


