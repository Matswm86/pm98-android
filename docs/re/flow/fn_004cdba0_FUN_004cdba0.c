// FUN_004cdba0  entry=004cdba0  size=30 bytes
// callers/callees expanded one level from seeds

void * __thiscall FUN_004cdba0(void *param_1,byte param_2)

{
  FUN_004cdbc0();
  if ((param_2 & 1) != 0) {
    operator_delete(param_1);
  }
  return param_1;
}


