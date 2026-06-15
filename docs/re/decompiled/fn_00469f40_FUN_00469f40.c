// FUN_00469f40  entry=00469f40  size=30 bytes
// callers/callees expanded one level from seeds

void * __thiscall FUN_00469f40(void *param_1,byte param_2)

{
  FUN_00469f60();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


