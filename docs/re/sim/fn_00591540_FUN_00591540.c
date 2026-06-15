// FUN_00591540  entry=00591540  size=30 bytes
// callers/callees expanded one level from seeds

void * __thiscall FUN_00591540(void *param_1,byte param_2)

{
  FUN_00591ba0();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


